const router=require("express").Router();
const auth = require("../middleware/auth").authCustomer


const controller = require("../controller/therocontroller")
const {validateSinginRequest,validatesaveuser,isRequestValidated}=require("../validators/therovalidation")



router.post("/loginuser",validateSinginRequest,isRequestValidated,controller.signup)

router.post("/saveuser" ,auth,validatesaveuser,isRequestValidated,controller.saveuser)
router.get("/getuser",auth,controller.getuser)
router.get("/getgamestate",auth,controller.getgamestate)
router.post("/claimtokens",auth,controller.send)



module.exports=router;
