import { IsEnum, IsOptional, IsPhoneNumber, IsString, Length } from 'class-validator';
import { Role, Locale } from '@prisma/client';

export class RequestOtpDto {
  @IsPhoneNumber('CM')
  phone: string;
}

export class VerifyOtpDto {
  @IsPhoneNumber('CM')
  phone: string;

  @IsString()
  @Length(4, 6)
  code: string;

  // required only on first-time signup
  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsEnum(Role)
  role?: Role;

  @IsOptional()
  @IsEnum(Locale)
  locale?: Locale;
}
