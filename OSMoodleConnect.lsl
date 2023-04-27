// Moodle LMS / Opensimulator Web Services
// Author: Josh Garrett - 2022
// Authorized for reuse under MIT License
// Latest Update: 4/27/23

// Enable Debugging
integer debug=0;

//Moodle Config - From Notecard
string configurationNotecardName = "Application.Config";
key notecardQueryId;
integer line;

string AvatarName;
string Fullname;
string Email;
string Username;
string Password;
string userID;

// Web Service Access Token
string accessToken = "";

key req_id;
key touch_req_id;
string name;

// Listen Config
integer listenHandle;

remove_listen_handles()
{
    llListenRemove(listenHandle);
}

init()
{
    listenHandle = llListen(777, "", NULL_KEY, "");
    name = llGetOwner();
    AvatarName = llKey2Name(name);

    if(llGetInventoryType(configurationNotecardName) != INVENTORY_NOTECARD)
    {
        llOwnerSay("Missing inventory notecard: " + configurationNotecardName);
        return;
    }

    line = 0;
    notecardQueryId = llGetNotecardLine(configurationNotecardName, line);
}

processConfiguration(string data)
{
    if(data == EOF)
    {
 
        // Check Access Token 
        if (accessToken == "") {
            if (debug==1) {
                llOwnerSay("Debug: Requesting Access Token");
                }
            state getAccessToken;
            }
        
        llOwnerSay(AvatarName + " is now authorized as " + Username);
        return;
    }

    if(data != "")
    {
        if(llSubStringIndex(data, "#") != 0)
        {
        //  find first equal sign
            integer i = llSubStringIndex(data, "=");

        //  if line contains equal sign
            if(i != -1)
            {
                string name = llGetSubString(data, 0, i - 1);
                string value = llGetSubString(data, i + 1, -1);
                list temp = llParseString2List(name, [" "], []);
                name = llDumpList2String(temp, " ");
                name = llToLower(name);
                temp = llParseString2List(value, [" "], []);
                value = llDumpList2String(temp, " ");
                if(name == "username")
                    Username = value;
                else if(name == "password")
                    Password = value;
                else
                    llOwnerSay("Unknown configuration value: " + name + " on line " + (string)line);

            }
        //  line does not contain equal sign
            else
            {
                llOwnerSay("Configuration could not be read on line " + (string)line);
            }
        }
    }

//  read the next line
    notecardQueryId = llGetNotecardLine(configurationNotecardName, ++line);
}

// Send Activity Update to LMS
sendLMSUpdate(string data)
{
    
    string regionname = llDumpList2String(llParseString2List(llGetRegionName(),[" "],[]),"%20");
    
    req_id = llHTTPRequest("https://SERVERNAME/webservice/rest/server.php?wstoken=" + accessToken + "&wsfunction=mod_data_add_entry&databaseid=1&data[0][fieldid]=1&data[0][value]=\"" + activityTitle + "\"&data[1][fieldid]=4&data[1][value]=\"" + AvatarName + "\"&data[2][fieldid]=6&data[2][value]=\"" + activityContent + "\"&data[3][fieldid]=7&data[3][value]=\"" + activityURL + "\"&moodlewsrestformat=" + wsformat, [HTTP_METHOD, "POST"],"");
        
    }

  http_response(key request_id, integer status, list metadata, string body) {
        if (req_id == request_id) {
            string object = llJsonGetValue(body,[0]); 
            string data = llJsonGetValue( object, ["id"] );
            userID = data;
            if (debug==1) {
                llOwnerSay("Debug body: " + body );
                 llOwnerSay("Debug: " + object );
                 llOwnerSay("Debug: " +  data);
                }            
           // state default;
 
        }
    
}

// Gain Access Token based on credentials
state getAccessToken 
{
    state_entry()
    {
        req_id = llHTTPRequest("https://SERVERNAME/login/token.php?username=" + Username + "&password=" + Password + "&service=moodle_mobile_app", [HTTP_METHOD, "POST"],"");
        
    }

  http_response(key request_id, integer status, list metadata, string body) {
        if (req_id == request_id) {
            string data = llJsonGetValue( body, ["token"] );
            accessToken = data;
            if (debug==1) {
                 llOwnerSay("Debug: " + body );
                 llOwnerSay("Debug: Got Access Token: " + accessToken );
                }            
            state getUserData;
 
        }
    }

}

// Get User details based on Access Token
state getUserData 
{
    state_entry()
    {
        req_id = llHTTPRequest("https://SERVERNAME/webservice/rest/server.php?wstoken=" + accessToken + "&wsfunction=core_user_get_users_by_field&field=username&values[0]=" + Username + "&moodlewsrestformat=" + wsformat, [HTTP_METHOD, "POST"],"");
        
    }

  http_response(key request_id, integer status, list metadata, string body) {
        if (req_id == request_id) {
            string object = llJsonGetValue(body,[0]); 
            userID = llJsonGetValue( object, ["id"] );
            Fullname = llJsonGetValue( object, ["fullname"] );
            Email = llJsonGetValue( object, ["email"] );
            //userID = dataID;
            
            if (debug==1) {
                 llOwnerSay("Debug: " + object );
                 llOwnerSay("Debug: Got User ID: " +  userID);
                 llOwnerSay("Debug: Got Fullname: " +  Fullname);
                }            
            state userLogin;
 
        }
    }

}

// Get User details based on Access Token
state userLogin 
{
    state_entry()
    {
        string regionname = llDumpList2String(llParseString2List(llGetRegionName(),[" "],[]),"%20");

        req_id = llHTTPRequest("https://SERVERNAME/webservice/rest/server.php?wstoken=" + accessToken + "&wsfunction=mod_data_add_entry&databaseid=1&data[0][fieldid]=1&data[0][value]=\"" + activityTitle + "\"&data[1][fieldid]=4&data[1][value]=\"" + AvatarName + "\"&data[2][fieldid]=6&data[2][value]=\"" + activityURL + "\"&data[3][fieldid]=7&data[3][value]=\"" + activityURL + "\"&moodlewsrestformat=" + wsformat, [HTTP_METHOD, "POST"],"");
        
    }

  http_response(key request_id, integer status, list metadata, string body) {
        if (req_id == request_id) {
            string object = llJsonGetValue(body,[0]); 
            string data = llJsonGetValue( object, ["id"] );
            userID = data;
            if (debug==1) {
                llOwnerSay("Debug body: " + body );
                 llOwnerSay("Debug: " + object );
                 llOwnerSay("Debug: Got User Login: " +  data);
                }            
            state default;
 
        }
    }

}

default
{
    on_rez(integer start_param)
    {
        accessToken = "";
        init();
    }

    changed(integer change)
    {
        if(change & (CHANGED_OWNER | CHANGED_INVENTORY))
            init();
    }

    state_entry()
    {
        init();
    }
    
    touch_start(integer total_number)
    {
        if (debug==1) {
        llSay(0, AvatarName + " is making request with access token: " + accessToken);
}
        touch_req_id = llHTTPRequest("https://SERVERNAME/webservice/rest/server.php?wstoken=" + accessToken + "&field=id&value=2&moodlewsrestformat=" + wsformat + "&wsfunction=" + wsfunction, [HTTP_METHOD, "POST"],"");

}

  
  http_response(key touch_request_id, integer status, list metadata, string body) {
        if (touch_req_id == touch_request_id) {
            
            if (debug==1) {
            if (llJsonValueType(body, []) == JSON_OBJECT)
            {
                llOwnerSay("The supplied string is a Json object.");
            } else {
                llOwnerSay("The supplied string is not a Json object."); // TRUE
            }
    
            if (llJsonValueType(body, [1]) == JSON_OBJECT)
            {
                llOwnerSay("The second element of the array is a Json object."); // TRUE
            } else {
                llOwnerSay("The second element of the array is not a Json object.");
            }
            }
            
            string data = llJsonGetValue( body, ["courses"] );
            list courses = llJson2List( data );
            
            string studentdata = llJsonGetValue( courses, ["contacts"] );
            list students = llJson2List( studentdata );
            //llSay(0, courses);
            
            string courseName = llJsonGetValue( courses, ["fullname"] );
            string studentName = llJsonGetValue( students, ["fullname"] );
            
            if (debug==1) {
                llSay(0, "Courses: " + data );
            }
            
            llOwnerSay("Touched");
            llOwnerSay("Course Name: " + courseName );
            llOwnerSay("Student Name: " + Fullname );
            llOwnerSay("Student Email: " + Email );
            llSetText("",<1,0,0>,1); 
 
        }
    }
    

    dataserver(key request_id, string data)
    {
        if(request_id == notecardQueryId)
            processConfiguration(data);
    }
}
