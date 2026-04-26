const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: process.env.SMTP_PORT || 587,
  secure: process.env.SMTP_PORT == 465, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

exports.sendDeptAdminWelcomeEmail = async (user, rawPassword, departmentName) => {
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
    console.warn('[EMAIL] SMTP credentials not set. Skipping email.');
    return;
  }

  const mailOptions = {
    from: `"Classlytics ERP" <${process.env.SMTP_USER}>`,
    to: user.email,
    subject: 'Your Department Admin Account',
    text: `Hello ${user.name},

Your account has been created.

Email: ${user.email}
Password: ${rawPassword}
Department: ${departmentName}

Please login and change your password.

Best regards,
Classlytics Team`,
    html: `<div style="font-family: sans-serif; line-height: 1.6; color: #333;">
      <h2>Hello ${user.name},</h2>
      <p>Your account has been created as a <b>Department Admin</b>.</p>
      <div style="background: #f4f4f4; padding: 15px; border-radius: 8px; margin: 20px 0;">
        <p style="margin: 0;"><b>Email:</b> ${user.email}</p>
        <p style="margin: 0;"><b>Password:</b> <code style="background: #eee; padding: 2px 4px;">${rawPassword}</code></p>
        <p style="margin: 0;"><b>Department:</b> ${departmentName}</p>
      </div>
      <p>Please login to the portal and change your password immediately.</p>
      <br>
      <p>Best regards,<br><b>Classlytics Team</b></p>
    </div>`,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[EMAIL] Welcome email sent to ${user.email}: ${info.messageId}`);
    return info;
  } catch (err) {
    console.error(`[EMAIL] Failed to send email to ${user.email}:`, err.message);
    throw err;
  }
};

exports.sendTeacherWelcomeEmail = async (user, rawPassword) => {
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
    console.warn('[EMAIL] SMTP credentials not set. Skipping email.');
    return;
  }

  const mailOptions = {
    from: `"Classlytics ERP" <${process.env.SMTP_USER}>`,
    to: user.email,
    subject: 'Your Teacher Account Credentials',
    text: `Hello ${user.name},

Your teacher account has been created on Classlytics.

Email: ${user.email}
Password: ${rawPassword}

Please login and change your password for security.

Best regards,
Classlytics Team`,
    html: `<div style="font-family: sans-serif; line-height: 1.6; color: #333;">
      <h2 style="color: #4F46E5;">Welcome to Classlytics, ${user.name}!</h2>
      <p>Your teacher account has been successfully created. You can now access your dashboard to manage classes, attendance, and students.</p>
      <div style="background: #F8FAFC; padding: 20px; border-radius: 12px; margin: 25px 0; border: 1px solid #E2E8F0;">
        <p style="margin: 0; color: #64748B; font-size: 14px;">ACCOUNT CREDENTIALS</p>
        <p style="margin: 10px 0 5px 0;"><b>Email:</b> ${user.email}</p>
        <p style="margin: 0;"><b>Password:</b> <code style="background: #EEF2FF; color: #4F46E5; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 16px;">${rawPassword}</code></p>
      </div>
      <p><b>Next Step:</b> Please login to the portal and update your password immediately from the settings menu.</p>
      <br>
      <hr style="border: 0; border-top: 1px solid #E2E8F0;">
      <p style="font-size: 12px; color: #94A3B8;">This is an automated message, please do not reply.</p>
      <p>Best regards,<br><b>Classlytics Administration</b></p>
    </div>`,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[EMAIL] Teacher welcome email sent to ${user.email}: ${info.messageId}`);
    return info;
  } catch (err) {
    console.error(`[EMAIL] Failed to send email to ${user.email}:`, err.message);
    throw err;
  }
};
