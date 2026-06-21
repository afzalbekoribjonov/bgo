import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { OtpService } from '../otp/otp.service';
import { SmsService } from '../sms/sms.service';
import { UsersModule } from '../users/users.module';
import { AdminUsersController } from './admin-users.controller';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';

@Module({
  imports: [
    UsersModule,
    // Secret'lar har imzo/tekshiruvda aniq beriladi (access va refresh — alohida).
    JwtModule.register({}),
  ],
  controllers: [AuthController, AdminUsersController],
  providers: [AuthService, OtpService, SmsService, JwtAuthGuard, RolesGuard],
})
export class AuthModule {}
