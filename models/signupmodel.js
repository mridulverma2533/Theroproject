const mongoose = require("mongoose");

const SignupSchema=new mongoose.Schema({
    metamaskaddress:{
        type:String
    }

},{timestamps:true,versionKey: false })


module.exports =mongoose.model("meta",SignupSchema);