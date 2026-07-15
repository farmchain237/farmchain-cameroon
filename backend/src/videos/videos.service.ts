import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';
import { PrismaService } from '../common/prisma.module';
import { VideoType } from '@prisma/client';

const MAX_DURATION_SEC = 60;

@Injectable()
export class VideosService {
  private s3: S3Client;

  constructor(private prisma: PrismaService, private config: ConfigService) {
    this.s3 = new S3Client({ region: this.config.get<string>('AWS_REGION') });
  }

  /** Step 1: mobile app calls this to get a presigned PUT URL before uploading the compressed 720p file. */
  async getUploadUrl(userId: string, contentType = 'video/mp4') {
    const key = `videos/${userId}/${randomUUID()}.mp4`;
    const command = new PutObjectCommand({
      Bucket: this.config.get<string>('S3_BUCKET'),
      Key: key,
      ContentType: contentType,
    });
    const uploadUrl = await getSignedUrl(this.s3, command, { expiresIn: 300 });
    return { uploadUrl, s3Key: key };
  }

  /** Step 2: after successful upload, save metadata. Thumbnail is generated async by a Lambda trigger on S3 PUT. */
  async saveMetadata(userId: string, params: {
    s3Key: string;
    type: VideoType;
    durationSec: number;
    recordedAt: string;
    lat?: number;
    lng?: number;
    listingId?: string;
    orderId?: string;
  }) {
    if (params.durationSec > MAX_DURATION_SEC) {
      throw new BadRequestException(`Vidéo trop longue (max ${MAX_DURATION_SEC}s)`);
    }

    const video = await this.prisma.accountabilityVideo.create({
      data: {
        userId,
        listingId: params.listingId,
        orderId: params.orderId,
        type: params.type,
        s3Key: params.s3Key,
        durationSec: params.durationSec,
        recordedAt: new Date(params.recordedAt),
      },
    });

    if (params.lat != null && params.lng != null) {
      await this.prisma.$executeRawUnsafe(
        `UPDATE accountability_videos SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography WHERE id = $3`,
        params.lng,
        params.lat,
        video.id,
      );
    }

    return video;
  }

  forListing(listingId: string) {
    return this.prisma.accountabilityVideo.findMany({ where: { listingId }, orderBy: { recordedAt: 'desc' } });
  }

  forOrder(orderId: string) {
    return this.prisma.accountabilityVideo.findMany({ where: { orderId }, orderBy: { recordedAt: 'desc' } });
  }
}
