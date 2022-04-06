const router=require("express").Router();
const auth = require("../middleware/auth").authCustomer


const controller = require("../controller/therocontroller")



router.post("/loginuser",controller.signup)

router.post("/saveuser" ,auth,controller.saveuser)
router.get("/getuser",auth,controller.getuser)
router.get("/getgamestate",auth,controller.getgamestate)



module.exports=router;
