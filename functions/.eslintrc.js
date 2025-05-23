const express = require("express");
const cors = require("cors");
const nodemailer = require("nodemailer");

const app = express();
app.use(cors());
app.use(express.json());

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "mollni.noreplay@gmail.com",
    pass: "evnheeibivhzwvtw", // App password
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
    console.error("Error sending mail:", err);
    res.status(500).send({ success: false, error: "Failed to send" });
  }
});

app.listen(3000, () => console.log("Email server running on http://localhost:3000"));
