const io = require("socket.io")(3000, {
  cors: {
    origin: "*",
  },
});

io.on("connection", (socket) => {
  console.log("✅ User connected:", socket.id);

  // Join a private room
  socket.on("join_room", (payload) => {
    console.log("🚩 join_room event triggered with payload:", payload);
    const roomId = payload.roomId || payload["roomId"];
    socket.join(roomId);
    console.log(`👥 User ${socket.id} joined room: ${roomId}`);
  });

  socket.onAny((event, payload) => {
    console.log(`📡 Event received: ${event} with payload:`, payload);
  });
  // Receive and forward message to room
  socket.on("send_message", ({ roomId, message, senderId }) => {
    console.log(`📨 Message from ${senderId} to room ${roomId}:`, message);
    socket.to(roomId).emit("receive_message", { message, senderId });
  });

  socket.on("disconnect", () => {
    console.log("❌ User disconnected:", socket.id);
  });
});

console.log("🚀 Socket.IO server running on port 3000");
