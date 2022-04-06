const jwt=require('jsonwebtoken');
exports.authCustomer=(req,res,next)=>{
    if(req.header('Authorization').replace('Bearer ', '')){
        const token=req.header('Authorization').replace('Bearer ', '');
        const user=jwt.verify(token,"this is my");
        req.user=user;
        if(req.user=="user"){
            return res.status(400).json("invalid user !")
         }
        
    }else{
        return res.status(400).json({message:'Authorization required'});
    }
   
    next();
}

// module.exports = Auth
// const jwt = require('jsonwebtoken')
// const User = require('../models/signupmodel')
// const auth = async (req, res, next) => {
// try {
// const token = req.header('Authorization').replace('Bearer ', '')
// const decoded = jwt.verify(token, 'this is my')
// const user = await User.findOne({ _id: decoded._id, 'tokens.token':
// token })
// if (!user) {
// throw new Error()
// }
// req.user = user
// next()
// } catch (e) {
// res.status(401).send({ error: 'Please authenticate.' })
// }
// }
// module.exports = auth