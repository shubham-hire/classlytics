const Razorpay = require('razorpay');
const crypto = require('crypto');
const db = require('../config/db');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'YOUR_TEST_KEY_ID',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'YOUR_TEST_SECRET'
});

exports.createOrder = async (req, res) => {
  try {
    const { parent_id, student_id, amount } = req.body;

    if (!parent_id || !student_id || !amount) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const options = {
      amount: Math.round(amount * 100), // amount in the smallest currency unit (paise)
      currency: "INR",
      receipt: `receipt_${Date.now()}`
    };

    const order = await razorpay.orders.create(options);

    if (!order) {
      return res.status(500).json({ success: false, message: 'Failed to create order' });
    }

    // Save order in DB with status PENDING
    await db.execute(
      `INSERT INTO payments (parent_id, student_id, amount, status, razorpay_order_id)
       VALUES (?, ?, ?, ?, ?)`,
      [parent_id, student_id, amount, 'PENDING', order.id]
    );

    res.status(200).json({
      success: true,
      order_id: order.id,
      amount: amount,
      key_id: process.env.RAZORPAY_KEY_ID || 'YOUR_TEST_KEY_ID'
    });

  } catch (error) {
    console.error('Error creating Razorpay order:', error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.verifyPayment = async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    const secret = process.env.RAZORPAY_KEY_SECRET || 'YOUR_TEST_SECRET';
    
    // Verify signature
    const hmac = crypto.createHmac('sha256', secret);
    hmac.update(razorpay_order_id + "|" + razorpay_payment_id);
    const generated_signature = hmac.digest('hex');

    if (generated_signature === razorpay_signature) {
      // Payment is successful
      await db.execute(
        `UPDATE payments SET status = 'SUCCESS', razorpay_payment_id = ? WHERE razorpay_order_id = ?`,
        [razorpay_payment_id, razorpay_order_id]
      );

      res.status(200).json({ success: true, message: 'Payment verified successfully' });
    } else {
      // Payment failed signature verification
      await db.execute(
        `UPDATE payments SET status = 'FAILED', razorpay_payment_id = ? WHERE razorpay_order_id = ?`,
        [razorpay_payment_id, razorpay_order_id]
      );
      res.status(400).json({ success: false, message: 'Invalid payment signature' });
    }

  } catch (error) {
    console.error('Error verifying payment:', error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};
