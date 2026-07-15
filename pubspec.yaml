import { Body, Controller, ForbiddenException, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { SecurityService } from './security.service';
import { DeviceType } from '@prisma/client';

@UseGuards(AuthGuard('jwt'))
@Controller('security')
export class SecurityController {
  constructor(private security: SecurityService) {}

  @Post('devices')
  register(
    @Req() req: any,
    @Body() body: { farmId: string; type: DeviceType; name: string; rtspUrl?: string },
  ) {
    return this.security.registerDevice(req.user.userId, body);
  }

  @Get('devices/:id/stream-url')
  async streamUrl(@Req() req: any, @Param('id') id: string) {
    try {
      const url = await this.security.getStreamUrl(id, req.user.userId);
      return { rtspUrl: url };
    } catch {
      throw new ForbiddenException();
    }
  }

  @Get('farms/:farmId/events')
  events(@Param('farmId') farmId: string) {
    return this.security.eventsForFarm(farmId);
  }
}
