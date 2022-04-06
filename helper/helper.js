const game = require("../models/gamestatemodel")
async function addGameData(_id, gamestate){
    try{

        let temp = {  userId:_id, gamestate }
        console.log(temp);
        const data = await game.findOne({userId:_id})
        if(data) {
            const gamedata = await game.findOneAndUpdate({userId:_id},{$set:{gamestate}},{new:true})
            // res.send(gamedata)
        }else{
            const gamedata = await game.create(temp)
            // res.send(gamedata)
        }
        // return gamedata
    }catch(e){
        console.log(e);
    }
}
module.exports={
    addGameData
}