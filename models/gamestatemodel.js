const mongoose = require("mongoose");


const GamestateSchema=new mongoose.Schema({
    gamestate:{
        type:String
    },
    userId:{
        type:mongoose.Types.ObjectId,
        ref:"meta"
    }

},{timestamps:true,versionKey: false })

module.exports =mongoose.model("gamestate",GamestateSchema);