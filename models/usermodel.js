const mongoose = require("mongoose");


const UserSchema=new mongoose.Schema({
    data:{
        type:String
    },
    userId:{
        type:mongoose.Schema.Types.ObjectId,
        ref: "meta"
    }


},{timestamps:true,versionKey: false })

module.exports =mongoose.model("user",UserSchema);

