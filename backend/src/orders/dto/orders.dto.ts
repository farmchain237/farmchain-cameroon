import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { PaymentProvider } from '@prisma/client';

export class CreateOrderDto {
  @IsString() listingId: string;
  @IsNumber() @Min(1) qtyKg: number;
  @IsEnum(PaymentProvider) provider: PaymentProvider;
}

export class ConfirmDeliveryDto {
  @IsNumber() lat: number;
  @IsNumber() lng: number;
}

export class MomoWebhookDto {
  @IsString() referenceId: string;
  @IsString() status: string; // SUCCESSFUL | FAILED | PENDING
}
