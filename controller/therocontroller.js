const User = require("../models/signupmodel")
const jwt = require("jsonwebtoken");
const saveuser = require("../models/usermodel")
const game = require("../models/gamestatemodel")
const websocket = require("ws");
const data = require("../helper/helper")
const conc = require("../contract")



exports.signup=async (req,res)=>{
    try{
        const user = await User.findOne({metamaskaddress:req.body.metamaskaddress})

         if(user){
            // const token = jwt.sign({ _id: user._id }, "this is my");
            const token = await jwt.sign({ _id: user._id },"this is my",{ expiresIn: '1d' });
             res.status(200).json({user,token})
      
         }else{
        const user = await User({
         metamaskaddress:req.body.metamaskaddress
        })
        const result = await user.save()
        const token = await jwt.sign({ _id: user._id},"this is my",{ expiresIn: '1d' } );
        // const token = jwt.sign({ _id: user._id }, "this is my");
        res.status(200).json({result,token})

         }


    }catch(e){
        console.log(e);
        res.status(500).json(e)
    
}
},

exports.saveuser = async (req,res)=>{
    try{
        const user = req.user
        const { data } = req.body
        let temp = {  userId: user._id,data }
        const dat =await saveuser.findOne({userId:user._id})
        // console.log(data)
        if(dat) {
            const gamedata = await saveuser.findOneAndUpdate({userId:user._id},{$set:{data}},{new:true})

            res.status(200).json(gamedata)
        }else{
            const result = await saveuser.create(temp)

            res.status(200).json(result)
            
        }



    }catch(e){
        console.log(e);
        res.send(e)
    }
},
exports.getuser= async(req,res)=>{
    try{
        const user = req.user

        const  data = await saveuser.findOne({userId: user._id})
        if(data){

            res.send(data)
        }else{
            res.send("invalid user")
        }

     

    }catch(e){
        console.log(e);
     
    }
},



exports.addgamestate = async (req, res)=>{
    try{

        const { gamestate,_id } = req.body
        console.log(_id)
    
    const result = data.addGameData(_id, gamestate)
    console.log(result);
        res.send(result)
    }catch(e){
        console.log(e);
    }
    
}



exports.getgamestate = async (req,res)=>{
    try{
        const user = req.user
          const data = await game.findOne({userId:user._id})
          if(data){

            res.send(data)
        }else{
            res.send("invalid user")
        }


    }catch(e){
        console.log(e);
        res.status(500).json(e)
    }
},
exports.send =async (req,res)=>{
    try{
        const {token} = req.body
        const data = await conc.contract.methods.ConvertFromInGameToken2THRAndTransfer(token).call()
        res.send(data)

    }catch(e){
        console.log(e);
        res.send(e)
    }
}


