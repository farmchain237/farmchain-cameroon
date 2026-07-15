import { Body, Controller, Param, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { OrdersService } from './orders.service';
import { PrismaService } from '../common/prisma.module';
import { CreateOrderDto, ConfirmDeliveryDto, MomoWebhookDto } from './dto/orders.dto';

@Controller('orders')
export class OrdersController {
  constructor(private orders: OrdersService, private prisma: PrismaService) {}

  @UseGuards(AuthGuard('jwt'))
  @Post()
  create(@Req() req: any, @Body() dto: CreateOrderDto) {
    return this.orders.create(req.user.userId, dto);
  }

  @UseGuards(AuthGuard('jwt'))
  @Post(':id/confirm-delivery')
  confirmDelivery(@Req() req: any, @Param('id') id: string, @Body() dto: ConfirmDeliveryDto) {
    return this.orders.confirmDelivery(id, req.user.userId, dto);
  }

  // MoMo calls this on payment completion. Verify MoMo's signature/IP allowlist
  // before trusting this in production — left as a TODO since it depends on
  // the exact webhook auth MTN issues per merchant.
  @Post('webhooks/momo')
  async momoWebhook(@Body() body: MomoWebhookDto) {
    if (body.status === 'SUCCESSFUL') {
      // referenceId maps 1:1 to the order via Payment.providerRef
      const payment = await this.findPaymentByRef(body.referenceId);
      if (payment) await this.orders.markEscrowed(payment.orderId, body.referenceId);
    }
    return { ok: true };
  }

  private async findPaymentByRef(referenceId: string) {
    return this.prisma.payment.findFirst({ where: { providerRef: referenceId } });
  }
}
