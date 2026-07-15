import { Type } from 'class-transformer';
import { IsArray, IsDateString, IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { CropType, Grade, Region } from '@prisma/client';

export class CreateListingDto {
  @IsEnum(CropType) cropType: CropType;
  @IsEnum(Region) region: Region;
  @IsNumber() @Min(1) qtyKg: number;
  @IsEnum(Grade) grade: Grade;
  @IsNumber() @Min(1) pricePerKg: number;
  @IsDateString() harvestDate: string;
  @IsArray() @IsString({ each: true }) photos: string[];
  @IsOptional() @IsNumber() lat?: number;
  @IsOptional() @IsNumber() lng?: number;
  @IsOptional() @IsString() farmId?: string;
}

export class SearchListingsDto {
  @IsOptional() @IsEnum(CropType) cropType?: CropType;
  @IsOptional() @IsEnum(Region) region?: Region;
  @IsOptional() @IsEnum(Grade) grade?: Grade;
  @IsOptional() @Type(() => Number) @IsNumber() minPrice?: number;
  @IsOptional() @Type(() => Number) @IsNumber() maxPrice?: number;
  // map bounds / radius search
  @IsOptional() @Type(() => Number) @IsNumber() lat?: number;
  @IsOptional() @Type(() => Number) @IsNumber() lng?: number;
  @IsOptional() @Type(() => Number) @IsNumber() radiusKm?: number;
  @IsOptional() @Type(() => Number) @IsNumber() page?: number = 1;
  @IsOptional() @Type(() => Number) @IsNumber() pageSize?: number = 20;
}
