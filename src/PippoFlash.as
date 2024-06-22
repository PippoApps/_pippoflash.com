package 
{
	import flash.display.Sprite;
	import flash.text.TextField;
    import com.pippoflash.utils.Debug;

	public class PippoFlash extends Sprite
	{
		public function PippoFlash()
		{
			var tf:TextField = new TextField();
			tf.text = "PippoFlash";
			addChild(tf);
			Debug.debug("Main", "PIppooooooooooooooooo")
		}
	}
}