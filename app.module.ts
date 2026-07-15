import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import axios from 'axios';
import { PrismaService } from '../common/prisma.module';
import { RequestOtpDto, VerifyOtpDto } from './dto/auth.dto';

const OTP_TTL_SECONDS = 5 * 60;

@Injectable()
export class AuthService {
  private redis: Redis;

  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) {
    this.redis = new Redis(this.config.get<string>('REDIS_URL')!);
  }

  private otpKey(phone: string) {
    return `otp:${phone}`;
  }

  async requestOtp(dto: RequestOtpDto) {
    const code = String(Math.floor(100000 + Math.random() * 900000));
    await this.redis.set(this.otpKey(dto.phone), code, 'EX', OTP_TTL_SECONDS);

    // Africa's Talking SMS send. Swap for Twilio if preferred.
    const atApiKey = this.config.get<string>('AT_API_KEY');
    const atUsername = this.config.get<string>('AT_USERNAME');
    if (atApiKey && atUsername) {
      await axios.post(
        'https://api.africastalking.com/version1/messaging',
        new URLSearchParams({
          username: atUsername,
          to: dto.phone,
          message: `FarmChain: votre code est ${code}. Valide 5 min.`,
        }),
        { headers: { apiKey: atApiKey, 'Content-Type': 'application/x-www-form-urlencoded' } },
      );
    } else {
      // dev fallback — do NOT ship this branch to production
      // eslint-disable-next-line no-console
      console.log(`[DEV OTP] ${dto.phone} -> ${code}`);
    }

    return { sent: true };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const stored = await this.redis.get(this.otpKey(dto.phone));
    if (!stored || stored !== dto.code) {
      throw new UnauthorizedException('Code invalide ou expiré');
    }
    await this.redis.del(this.otpKey(dto.phone));

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
