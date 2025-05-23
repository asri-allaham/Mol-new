const axios = require("axios");

axios.post("http://localhost:3000/sendResetCode", {
    email: "mollni.noreplay@gmail.com",
    code: "123456",
})
    .then(res => {
        console.log("✅ Email sent:", res.data);
    })
    .catch(err => {
        console.error("❌ Error sending email:", err.response?.data || err.message);
    });
