/**
 * Created by caijingxiao on 2017/8/1.
 */
package game.world.entity.skill.controller
{
    import easiest.core.IClear;
    import easiest.managers.FrameManager;

    import game.world.entity.skill.model.SkillData;
    import game.world.entity.skill.view.SkillAvatar;

    public class Skill implements IClear
    {
        private var _data:SkillData;
        private var _avatar:SkillAvatar;
        private var _animation:Animation;

        public function Skill()
        {
            super();

            _data = new SkillData();
            _avatar = new SkillAvatar();
        }

        public function clear():void
        {
            _data.clear();
            _avatar.clear();
        }

        public function update():void
        {
            _animation.update(FrameManager.deltaTime);
            _avatar.update(_data, _animation.frame);
        }
    }
}
