import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { VideosService } from './videos.service';
import { VideoType } from '@prisma/client';

@UseGuards(AuthGuard('jwt'))
@Controller('videos')
export class VideosController {
  constructor(private videos: VideosService) {}

  @Post('upload-url')
  getUploadUrl(@Req() req: any, @Query('contentType') contentType?: string) {
    return this.videos.getUploadUrl(req.user.userId, contentType);
  }

  @Post()
  saveMetadata(
    @Req() req: any,
    @Body()
    body: {
      s3Key: string;
      type: VideoType;
      durationSec: number;
      recordedAt: string;
      lat?: number;
      lng?: number;
      listingId?: string;
      orderId?: string;
    },
  ) {
    return this.videos.saveMetadata(req.user.userId, body);
  }

  @Get('listing/:listingId')
  forListing(@Param('listingId') listingId: string) {
    return this.videos.forListing(listingId);
  }

  @Get('order/:orderId')
  forOrder(@Param('orderId') orderId: string) {
    return this.videos.forOrder(orderId);
  }
}
