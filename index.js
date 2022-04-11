const express = require("express")


const app = express();
const cors = require("cors")
const solc = require('solc');
const fs = require('fs');

require("./db")
const bp = require("body-parser")
app.use(bp.json());
app.use(bp.urlencoded({ extended: false }));

const indexTest = require("./helper/helper")

const port = process.env.PORT || 8000;

app.use(express.json());
const userroutes = require("./routes/theroroutes");



app.use(cors())


app.use(userroutes)





 const server = app.listen(port,()=>{
    console.log(`server running on port ${port}`);
})
const websocket = require("ws")
const wss = new websocket.Server({server},()=>{
    console.log("server started");
})

wss.on("connection",(ws)=>{
  ws.on("message", (message)=>{
    // const data = require("./controller/therocontroller").addgamestate
    let result = JSON.parse(message.toString());
     indexTest.addGameData(result._id, result.gamestate)
     ws.send("success")
  })
})


