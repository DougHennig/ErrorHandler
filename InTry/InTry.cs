using System;

namespace InTry
{
    /// <summary>
    /// Created by Christof Wollenhaupt. Determines whether a TRY is active by attempting
    /// to RETURN TO MASTER.
    /// </summary>
    public static class InTry
    {
        public static bool IsTryActive(dynamic vfp)
        {
            String msg = "";
            try
            {
                vfp.DoCmd("return to master");
            }
            catch (Exception e)
            {
                msg = e.Message;
            }

            return msg.Length > 6 && msg.Substring(0, 6) == "2060 :";
        }
    }
}
