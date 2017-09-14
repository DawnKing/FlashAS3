/**
 * Created by caijingxiao on 2017/7/25.
 */
package game.world.entity.npc.model
{
    import game.world.entity.base.model.EntityData;

    import tempest.data.map.point.Tb_point_teleport;

    public class TeleportData extends EntityData
    {
        public var teleport:Tb_point_teleport;

        public function TeleportData()
        {
            super();
        }
    }
}
