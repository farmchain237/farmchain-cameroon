import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma.module';
import { MomoProvider } from './payments/momo.provider';
import { OrangeMoneyProvider } from './payments/orange-money.provider';
import { CreateOrderDto, ConfirmDeliveryDto } from './dto/orders.dto';
import { PaymentProvider } from '@prisma/client';

const PLATFORM_FEE_RATE = 0.01; // 1%

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private momo: MomoProvider,
    private orange: OrangeMoneyProvider,
  ) {}

  async create(buyerId: string, dto: CreateOrderDto) {
    const listing = await this.prisma.listing.findUnique({ where: { id: dto.listingId } });
    if (!listing || listing.status !== 'ACTIVE') {
      throw new BadRequestException('Annonce indisponible');
    }
    const buyer = await this.prisma.user.findUnique({ where: { id: buyerId } });
    if (!buyer) throw new NotFoundException('Acheteur introuvable');

    const totalPrice = Number(listing.pricePerKg) * dto.qtyKg;
    const fee = totalPrice * PLATFORM_FEE_RATE;

    const order = await this.prisma.order.create({
      data: {
        listingId: listing.id,
        buyerId,
        qtyKg: dto.qtyKg,
        totalPriceXaf: totalPrice,
        feeXaf: fee,
        status: 'PAYMENT_PENDING',
      },
    });

    const provider = dto.provider === PaymentProvider.MTN_MOMO ? this.momo : this.orange;
    const { referenceId } = await provider.requestToPay({
      amountXaf: totalPrice,
      payerPhone: buyer.phone,
      externalId: order.id,
    });

    await this.prisma.payment.create({
      data: {
        orderId: order.id,
        provider: dto.provider,
        providerRef: referenceId,
        amountXaf: totalPrice,
        status: 'PENDING',
        isEscrow: true,
      },
    });

    return { order, paymentReference: referenceId };
  }

  /** Called by MoMo/Orange webhook or a polling job when payment clears. Funds move to ESCROWED, not yet farmer. */
  async markEscrowed(orderId: string, providerRef: string) {
    await this.prisma.payment.updateMany({
      where: { orderId, providerRef },
      data: { status: 'SUCCESS' },
    });
    await this.prisma.order.update({
      where: { id: orderId },
      data: { status: 'ESCROWED' },
    });
    await this.prisma.listing.update({
      where: { id: (await this.prisma.order.findUniqueOrThrow({ where: { id: orderId } })).listingId },
      data: { status: 'RESERVED' },
    });
  }

  /** Transporter confirms GPS delivery -> auto-release escrow to farmer minus platform fee. */
  async confirmDelivery(orderId: string, transporterId: string, dto: ConfirmDeliveryDto) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Commande introuvable');
    if (order.status !== 'ESCROWED' && order.status !== 'IN_TRANSIT') {
      throw new BadRequestException('Commande non prête pour livraison');
    }

    await this.prisma.order.update({
      where: { id: orderId },
      data: {
        transporterId,
        status: 'DELIVERED',
        deliveredAt: new Date(),
      },
    });
    await this.prisma.$executeRawUnsafe(
      `UPDATE orders SET "deliveryGps" = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography WHERE id = $3`,
      dto.lng,
      dto.lat,
      orderId,
    );

    // Auto-release: in production, wire this to the disbursement API (MoMo Disbursements /
    // Orange payout) rather than just flipping DB status. Kept explicit here so the money
    // movement is a distinct, auditable step from "delivery confirmed".
    await this.releaseFunds(orderId);

    return { released: true };
  }

  private async releaseFunds(orderId: string) {
    await this.prisma.order.update({
      where: { id: orderId },
      data: { status: 'RELEASED', releasedAt: new Date() },
    });
    await this.prisma.payment.updateMany({
      where: { orderId },
      data: { releasedAt: new Date() },
    });
    // TODO: call momo.disbursementToFarmer(...) / orange payout here with (totalPriceXaf - feeXaf)
  }
}
