import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

/**
 * Orange Money Cameroon Web Payment API.
 * Mirrors MomoProvider's shape so OrdersService can treat providers polymorphically.
 * Fill in exact endpoint paths from the merchant onboarding docs Orange sends you —
 * they differ slightly by country deployment.
 */
@Injectable()
export class OrangeMoneyProvider {
  constructor(private config: ConfigService) {}

  private async getAccessToken(): Promise<string> {
    const res = await axios.post(
      'https://api.orange.com/oauth/v3/token',
      new URLSearchParams({ grant_type: 'client_credentials' }),
      {
        auth: {
          username: this.config.get<string>('ORANGE_MONEY_CLIENT_ID')!,
          password: this.config.get<string>('ORANGE_MONEY_CLIENT_SECRET')!,
        },
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      },
    );
    return res.data.access_token;
  }

  async requestToPay(params: { amountXaf: number; payerPhone: string; externalId: string }) {
    const token = await this.getAccessToken();
    const res = await axios.post(
      'https://api.orange.com/orange-money-webpay/cm/v1/webpayment',
      {
        merchant_key: this.config.get<string>('ORANGE_MONEY_MERCHANT_KEY'),
        currency: 'XAF',
        order_id: params.externalId,
        amount: params.amountXaf,
        return_url: 'https://farmchain.cm/payment/return',
        cancel_url: 'https://farmchain.cm/payment/cancel',
        notif_url: 'https://api.farmchain.cm/api/v1/orders/webhooks/orange',
        lang: 'fr',
      },
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return { referenceId: res.data.pay_token, payUrl: res.data.payment_url };
  }

  async getStatus(referenceId: string) {
    const token = await this.getAccessToken();
    const res = await axios.post(
      'https://api.orange.com/orange-money-webpay/cm/v1/transactionstatus',
      {
        order_id: referenceId,
        amount: undefined, // Orange requires amount+pay_token per their spec — wire up once merchant docs confirm exact payload
        pay_token: referenceId,
      },
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return res.data;
  }
}
