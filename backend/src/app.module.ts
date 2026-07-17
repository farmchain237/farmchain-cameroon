import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerModule } from '@nestjs/throttler';

import { PrismaModule } from './common/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ListingsModule } from './listings/listings.module';
import { OrdersModule } from './orders/orders.module';
import { ChatModule } from './chat/chat.module';
import { VideosModule } from './videos/videos.module';
import { SecurityModule } from './security/security.module';
import { EmployeesModule } from './employees/employees.module';
import { ReportsModule } from './reports/reports.module';

import { AdminModule } from './admin/admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ScheduleModule.forRoot(),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]),
    PrismaModule,
    AuthModule,
    UsersModule,
    ListingsModule,
    OrdersModule,
    ChatModule,
    VideosModule,
    SecurityModule,
    EmployeesModule,
    ReportsModule,
    AdminModule,
  ],
})
export class AppModule {}
