import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as mqtt from 'mqtt';
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';
import { PrismaService } from '../common/prisma.module';
import { DeviceType, SecurityEventType } from '@prisma/client';

@Injectable()
export class SecurityService implements OnModuleInit {
  private readonly logger = new Logger(SecurityService.name);
  private client: mqtt.MqttClient;

  constructor(private prisma: PrismaService, private config: ConfigService) {}

  onModuleInit() {
    this.client = mqtt.connect(this.config.get<string>('MQTT_URL')!);

    this.client.on('connect', () => {
      this.logger.log('Connected to MQTT broker');
      // wildcard: farmchain/security/{deviceId}/{event}
      this.client.subscribe('farmchain/security/+/+');
    });

    this.client.on('message', async (topic, payload) => {
      const parts = topic.split('/'); // ['farmchain','security', deviceId, event]
      const deviceId = parts[2];
      const eventKind = parts[3];
      await this.handleDeviceMessage(deviceId, eventKind, payload.toString());
    });
  }

  private async handleDeviceMessage(deviceId: string, eventKind: string, rawPayload: string) {
    let data: any = {};
    try {
      data = JSON.parse(rawPayload);
    } catch {
      /* non-JSON payload from a bare sensor — ignore parse errors, keep raw */
    }

    const device = await this.prisma.securityDevice.findUnique({ where: { id: deviceId } });
    if (!device) {
      this.logger.warn(`Message from unknown device ${deviceId}`);
      return;
    }

    if (eventKind === 'motion') {
      await this.recordEvent(deviceId, SecurityEventType.MOTION_DETECTED, data.snapshotUrl, data);
      await this.pushNotification(device.ownerId, 'Mouvement détecté', device.name);
    } else if (eventKind === 'status') {
      const isOnline = data.status === 'online';
      await this.prisma.securityDevice.update({
        where: { id: deviceId },
        data: { isOnline, lastSeenAt: new Date() },
      });
      await this.recordEvent(
        deviceId,
        isOnline ? SecurityEventType.CAMERA_ONLINE : SecurityEventType.CAMERA_OFFLINE,
        undefined,
        data,
      );
      if (!isOnline) await this.pushNotification(device.ownerId, 'Caméra hors ligne', device.name);
    }
  }

  private async recordEvent(deviceId: string, type: SecurityEventType, snapshotUrl?: string, metadata?: any) {
    return this.prisma.securityEvent.create({
      data: { deviceId, type, snapshotUrl, metadata },
    });
  }

  private async pushNotification(userId: string, title: string, body: string) {
    // Wire to FCM here (firebase-admin). Left as a hook so this module doesn't
    // hard-depend on Firebase credentials during local dev.
    this.logger.log(`[FCM stub] -> ${userId}: ${title} — ${body}`);
  }

  // ── Device registry ────────────────────────────────────

  private getEncKey(): Buffer {
    const b64 = this.config.get<string>('DEVICE_SECRET_ENC_KEY');
    if (!b64) throw new Error('DEVICE_SECRET_ENC_KEY not configured');
    return Buffer.from(b64, 'base64'); // must be 32 bytes for AES-256
  }

  private encryptRtsp(rtspUrl: string): string {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.getEncKey(), iv);
    const enc = Buffer.concat([cipher.update(rtspUrl, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    return Buffer.concat([iv, tag, enc]).toString('base64');
  }

  private decryptRtsp(blob: string): string {
    const buf = Buffer.from(blob, 'base64');
    const iv = buf.subarray(0, 12);
    const tag = buf.subarray(12, 28);
    const enc = buf.subarray(28);
    const decipher = createDecipheriv('aes-256-gcm', this.getEncKey(), iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(enc), decipher.final()]).toString('utf8');
  }

  async registerDevice(ownerId: string, params: { farmId: string; type: DeviceType; name: string; rtspUrl?: string }) {
    const device = await this.prisma.securityDevice.create({
      data: {
        ownerId,
        farmId: params.farmId,
        type: params.type,
        name: params.name,
        rtspUrlEnc: params.rtspUrl ? this.encryptRtsp(params.rtspUrl) : undefined,
      },
    });
    // topic is only assignable once we have the device id
    const mqttTopic = `farmchain/security/${device.id}/motion`;
    return this.prisma.securityDevice.update({ where: { id: device.id }, data: { mqttTopic } });
  }

  async getStreamUrl(deviceId: string, requesterId: string) {
    const device = await this.prisma.securityDevice.findUniqueOrThrow({ where: { id: deviceId } });
    if (device.ownerId !== requesterId) {
      throw new Error('Not authorized to view this device'); // swap for ForbiddenException in real controller
    }
    return device.rtspUrlEnc ? this.decryptRtsp(device.rtspUrlEnc) : null;
  }

  eventsForFarm(farmId: string) {
    return this.prisma.securityEvent.findMany({
      where: { device: { farmId } },
      include: { device: true },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }
}
