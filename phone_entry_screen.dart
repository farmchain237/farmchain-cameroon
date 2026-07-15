import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ChatService } from './chat.service';
import { CropType, Region } from '@prisma/client';

@UseGuards(AuthGuard('jwt'))
@Controller('chat')
export class ChatController {
  constructor(private chat: ChatService) {}

  @Post('token')
  token(@Req() req: any) {
    return this.chat.issueToken(req.user.userId);
  }

  @Post('channels/listing')
  listingChannel(@Req() req: any, @Body('listingId') listingId: string) {
    return this.chat.getOrCreateListingChannel(listingId, req.user.userId);
  }

  @Post('channels/region-crop')
  regionCropChannel(@Req() req: any, @Body() body: { crop: CropType; region: Region }) {
    return this.chat.getOrCreateRegionCropChannel(body.crop, body.region, req.user.userId);
  }
}
