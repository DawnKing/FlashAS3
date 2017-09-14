/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package easiest.debug
{
    public class Assert
    {
        public static function assertEquals1(expected:Object, actual:Object):void
        {
            CONFIG::debug
            {
                failNotEquals("", expected, actual);
            }
        }

        public static function assertEquals(message:String, expected:Object, actual:Object):void
        {
            CONFIG::debug
			{
                failNotEquals(message, expected, actual);
            }
        }

        public static function failNotEquals( message:String, expected:Object, actual:Object ):void
        {
            CONFIG::debug
            {
                if ( expected != actual )
                    failWithUserMessage(message, "expected:<" + expected + "> but was:<" + actual + ">");
            }
        }

        public static function assertTrue1(condition:Boolean):void
        {
            CONFIG::debug
            {
                failNotTrue("", condition);
            }
        }

        public static function assertTrue(message:String, condition:Boolean):void
        {
            CONFIG::debug
            {
                failNotTrue(message, condition);
            }
        }

        public static function failNotTrue( message:String, condition:Boolean ):void
        {
            CONFIG::debug
            {
                if ( !condition )
                    failWithUserMessage(message, "expected true but was false");
            }
        }

        public static function assertFalse1(condition:Boolean):void
        {
            CONFIG::debug
            {
                failTrue("", condition);
            }
        }

        public static function assertFalse(message:String, condition:Boolean):void
        {
            CONFIG::debug
            {
                failTrue(message, condition);
            }
        }

        public static function failTrue(message:String, condition:Boolean):void
        {
            CONFIG::debug
            {
                if ( condition )
                    failWithUserMessage(message, "expected false but was true");
            }
        }

        public static function assertNull1(object:Object):void
        {
            CONFIG::debug
            {
                failNotNull("", object);
            }
        }


        public static function assertNull(message:String, object:Object):void
        {
            CONFIG::debug
            {
                failNotNull(message, object);
            }
        }

        public static function failNull(message:String, object:Object):void
        {
            CONFIG::debug
            {
                if ( object == null )
                    failWithUserMessage(message, "object was null: " + object);
            }
        }

        public static function assertNotNull1(object:Object):void
        {
            CONFIG::debug
            {
                failNull("", object);
            }
        }

        public static function assertNotNull(message:String, object:Object):void
        {
            CONFIG::debug
            {
                failNull(message, object);
            }
        }

        public static function failNotNull(message:String, object:Object):void
        {
            CONFIG::debug
            {
                if ( object != null )
                    failWithUserMessage(message, "object was not null: " + object);
            }
        }

        public static function fail(failMessage:String = ""):void
        {
            CONFIG::debug
            {
                throw new Error(failMessage);
            }
        }

        private static function failWithUserMessage(userMessage:String, failMessage:String):void
        {
            CONFIG::debug
            {
                if ( userMessage.length > 0 )
                    userMessage = userMessage + " - ";

                throw new Error( userMessage + failMessage );
            }
        }
    }
}