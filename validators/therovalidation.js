const {check,validationResult}=require("express-validator");

exports.validateSinginRequest=[
    check('metamaskaddress')
    .notEmpty()
    .withMessage("metamaskaddress is required")

];
exports.validatesaveuser=[
    check('data')
    .notEmpty()
    .withMessage("data is required")

];

exports.isRequestValidated=(req,res,next)=>{
    const errors=validationResult(req);
   //  console.log(errors);
    if(errors && errors.errors.length>0){
       return  res.status(400).json({error:errors.errors[0].msg});
   }
    next();
   }