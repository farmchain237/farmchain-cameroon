import { Injectable, UnauthorizedException, BadRequestException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import axios from 'axios';
import { PrismaService } from '../common/prisma.module';
import { RequestOtpDto, VerifyOtpDto } from './dto/auth.dto';

const OTP_TTL_SECONDS = 15 * 60;

@Injectable()
export class AuthService {
  private redis: Redis;
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) {
    const redisUrl = this.config.get<string>('REDIS_URL');
    this.logger.log(`Connecting to Redis at: ${redisUrl ? redisUrl.replace(/:\/\/.*@/, '://***@') : 'NOT SET'}`);
    this.redis = new Redis(redisUrl!);
    this.redis.on('connect', () => this.logger.log('Redis connected successfully'));
    this.redis.on('error', (err) => this.logger.error(`Redis error: ${err.message}`));
  }

  private otpKey(phone: string) {
    return `otp:${phone}`;
  }

  async requestOtp(dto: RequestOtpDto) {
    const code = String(Math.floor(100000 + Math.random() * 900000));
    try {
      await this.redis.set(this.otpKey(dto.phone), code, 'EX', OTP_TTL_SECONDS);
      this.logger.log(`[OTP SAVED] ${dto.phone} -> ${code}`);
      const saved = await this.redis.get(this.otpKey(dto.phone));
      this.logger.log(`[OTP VERIFY SAVE] Retrieved: ${saved} (matches: ${saved === code})`);
    } catch (err) {
      this.logger.error(`[REDIS ERROR] Failed to save OTP: ${err.message}`);
      throw new Error('Failed to save OTP code');
    }
    const atApiKey = this.config.get<string>('AT_API_KEY');
    const atUsername = this.config.get<string>('AT_USERNAME');
    if (atApiKey && atUsername) {
      await axios.post(
        'https://api.africastalking.com/version1/messaging',
        new URLSearchParams({
          username: atUsername,
          to: dto.phone,
          message: `AGROFAMILY: your code is ${code}. Valid for 15 min.`,
        }),
        { headers: { apiKey: atApiKey, 'Content-Type': 'application/x-www-form-urlencoded' } },
      );
    } else {
      console.log(`[DEV OTP] ${dto.phone} -> ${code}`);
    }
    return { sent: true };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    this.logger.log(`[OTP VERIFY] Checking ${dto.phone}: entered=${dto.code}`);
    const stored = await this.redis.get(this.otpKey(dto.phone));
    this.logger.log(`[OTP VERIFY] Stored code: ${stored}`);
    if (!stored || stored !== dto.code) {
      this.logger.warn(`[OTP VERIFY] FAILED - stored: ${stored}, entered: ${dto.code}`);
      throw new UnauthorizedException('Code invalide ou expiré');
    }
    await this.redis.del(this.otpKey(dto.phone));
    this.logger.log(`[OTP VERIFY] SUCCESS for ${dto.phone}`);

    let user = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
    if (!user) {
      if (!dto.fullName || !dto.role) {
        throw new BadRequestException('fullName et role requis pour un nouveau compte');
      }
      user = await this.prisma.user.create({
        data: {
          phone: dto.phone,
          fullName: dto.fullName,
          role: dto.role,
          locale: dto.locale ?? 'fr_CM',
          isVerified: true,
        },
      });
    }
    const token = await this.jwt.signAsync({ sub: user.id, role: user.role });
    return { token, user };
  }
}
