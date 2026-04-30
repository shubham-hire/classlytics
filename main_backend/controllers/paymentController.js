const Razorpay = require('razorpay');
const crypto = require('crypto');
const db = require('../config/db');

let razorpay;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
    razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
}

exports.createOrder = async (req, res) => {
    try {
        const { amount, student_id } = req.body;
        
        if (!amount || !student_id) {
            return res.status(400).json({ error: 'amount and student_id are required' });
        }

        if (!razorpay) {
            return res.status(500).json({ error: 'Payment gateway is not configured. Please set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.' });
        }

        const options = {
            amount: Math.round(amount * 100), // amount in paise
            currency: 'INR',
            receipt: `receipt_${student_id}_${Date.now()}`
        };

        const order = await razorpay.orders.create(options);
        
        // Save the pending payment to the database
        await db.execute(
            'INSERT INTO payments (student_id, amount, status, razorpay_order_id) VALUES (?, ?, ?, ?)',
            [student_id, amount, 'PENDING', order.id]
        );

        res.status(200).json({ id: order.id, amount: order.amount, currency: order.currency });
    } catch (error) {
        console.error('Create Order Error:', error);
        res.status(500).json({ error: 'Failed to create order' });
    }
};

exports.verifyPayment = async (req, res) => {
    try {
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

        const body = razorpay_order_id + "|" + razorpay_payment_id;

        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(body.toString())
            .digest('hex');

        if (expectedSignature === razorpay_signature) {
            // Signature is valid, update payment status
            await db.execute(
                'UPDATE payments SET status = ?, razorpay_payment_id = ? WHERE razorpay_order_id = ?',
                ['SUCCESS', razorpay_payment_id, razorpay_order_id]
            );

            // Fetch the payment details to update fees
            const [payments] = await db.execute('SELECT student_id, amount FROM payments WHERE razorpay_order_id = ?', [razorpay_order_id]);
            if (payments.length > 0) {
                const { student_id, amount } = payments[0];

                // Update student_fee_assignments paid_amount
                const [feeAssignments] = await db.execute('SELECT id, total_amount, paid_amount FROM student_fee_assignments WHERE student_id = ? ORDER BY due_date ASC', [student_id]);
                if (feeAssignments.length > 0) {
                    const fa = feeAssignments[0];
                    const newPaid = parseFloat(fa.paid_amount) + parseFloat(amount);
                    const newStatus = newPaid >= parseFloat(fa.total_amount) ? 'Paid' : 'Partial';
                    await db.execute('UPDATE student_fee_assignments SET paid_amount = ?, status = ? WHERE id = ?', [newPaid, newStatus, fa.id]);
                }

                // Also update the older 'fees' table
                const [fees] = await db.execute('SELECT id, paid_amount, total_fee FROM fees WHERE student_id = ? ORDER BY id DESC LIMIT 1', [student_id]);
                if (fees.length > 0) {
                    const f = fees[0];
                    const newPaid = parseFloat(f.paid_amount) + parseFloat(amount);
                    await db.execute('UPDATE fees SET paid_amount = ? WHERE id = ?', [newPaid, f.id]);
                }
            }

            res.status(200).json({ success: true, message: 'Payment verified successfully' });
        } else {
            await db.execute(
                'UPDATE payments SET status = ? WHERE razorpay_order_id = ?',
                ['FAILED', razorpay_order_id]
            );
            res.status(400).json({ success: false, error: 'Invalid signature' });
        }
    } catch (error) {
        console.error('Verify Payment Error:', error);
        res.status(500).json({ error: 'Failed to verify payment' });
    }
};
