import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { MomoProvider } from './payments/momo.provider';
import { OrangeMoneyProvider } from './payments/orange-money.provider';

@Module({
  providers: [OrdersService, MomoProvider, OrangeMoneyProvider],
  controllers: [OrdersController],
})
export class OrdersModule {}
