import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { StreamChat } from 'stream-chat';
import { PrismaService } from '../common/prisma.module';
import { CropType, Region } from '@prisma/client';

@Injectable()
export class ChatService {
  private stream: StreamChat;

  constructor(private prisma: PrismaService, private config: ConfigService) {
    this.stream = StreamChat.getInstance(
      this.config.get<string>('STREAM_API_KEY')!,
      this.config.get<string>('STREAM_API_SECRET')!,
    );
  }

  /** Mobile/web client calls this after login to get a Stream user token. */
  async issueToken(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    await this.stream.upsertUser({ id: user.id, name: user.fullName, role: 'user' });
    const token = this.stream.createToken(user.id);
    return { token, streamUserId: user.id };
  }

  /** Auto-create (or fetch) the channel tied to a listing, first time someone messages on it. */
  async getOrCreateListingChannel(listingId: string, initiatorId: string) {
    const existing = await this.prisma.chatChannel.findUnique({ where: { listingId } });
    if (existing) return existing;

    const listing = await this.prisma.listing.findUniqueOrThrow({ where: { id: listingId } });
    const channel = this.stream.channel('messaging', `listing-${listingId}`, {
      created_by_id: initiatorId,
      members: [initiatorId, listing.farmerId],
    } as any);
    await channel.create();

    return this.prisma.chatChannel.create({
      data: {
        streamChannelId: channel.id!,
        type: 'LISTING',
        listingId,
      },
    });
  }

  /** Public moderated region+crop group, e.g. "Maïs Centre". Idempotent by regionCropKey. */
  async getOrCreateRegionCropChannel(crop: CropType, region: Region, initiatorId: string) {
    const key = `${crop}_${region}`;
    const existing = await this.prisma.chatChannel.findFirst({ where: { regionCropKey: key } });
    if (existing) return existing;

    const channel = this.stream.channel('team', `group-${key.toLowerCase()}`, {
      created_by_id: initiatorId,
      name: `${crop} ${region}`,
    } as any);
    await channel.create();

    return this.prisma.chatChannel.create({
      data: {
        streamChannelId: channel.id!,
        type: 'REGION_CROP',
        regionCropKey: key,
      },
    });
  }
}
