express = require("express");
cors = require("cors");
nodemailer = require("nodemailer");

const app = express();
app.use(cors());
app.use(express.json());

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "mollni.noreplay@gmail.com",
    pass: "evnheeibivhzwvtw",
  },
});

app.post("/sendResetCode", async (req, res) => {
  const { email, code } = req.body;

  const message = `
    Dear ${email},

    You have requested to reset your password for your Mollni account.
    👉 Your Reset Code: ${code}

    Please ignore if not requested.
  `;

  try {
    await transporter.sendMail({
      from: "Mollni Support <mollni.noreplay@gmail.com>",
      to: email,
      subject: "Mollni Password Reset Code",
      text: message,
    });

    res.send({ success: true });
  } catch (err) {
    console.error("❌ Error sending email:", err);
    res.status(500).send({ success: false, error: "Failed to send email" });
  }
});

app.listen(3000, '0.0.0.0', () => console.log("✅ Email server running on http://0.0.0.0:3000"));
