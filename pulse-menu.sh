#!/bin/bash
temp_file="./temp_file_usernames"
#rm temp file if already in system
rm $temp_file
#normalize pulse output file 
clean_data(){
        read -p "Pulse Output file to 'normalize': " dirty_file
        tail -n +2 "$dirty_file"|cut -d , -f 1|sed 's/\"//g'|head -n 100|tr "\n" ","|sed '$ s/.$//'|pbcopy
        echo "Copied to clipboard"
}
######### user name option
username_func(){
    if [ -z "$1" ]; then
        read -p "Paste usernames (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    #clean data by removing new lines
    pulse_var=${initial_var//$'\n'/}
        pulse_body=$(IFS=","
        #loop to use each value to create a json query
        for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"match_phrase\": {
                \"username\": \"${pulse_value}\"
            }
            },";done)
        echo -e "$pulse_body"|sed \$d >> $temp_file
        unset $pulse_body
}
image_func(){
    if [ -z "$1" ]; then
        read -p "Paste usernames (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    pulse_var=${initial_var//$'\n'/}
        pulse_body=$(IFS=","
        for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"match_phrase\": {
                \"image\": \"${pulse_value}\"
            }
            },";done)
        echo -e "$pulse_body"|sed \$d >> $temp_file
        unset $pulse_body
}
geo_func(){
    ######### Geo Location option 
    if [ -z "$1" ]; then
        read -p "Paste Locations (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    pulse_var=${initial_var//$'\n'/}
        pulse_body=$(IFS=","
        for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
        {
        \"wildcard\": {
        \"author_place\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"meta.geo_place.results.value\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"meta.author_geo_place.results.value\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"doc.place.full_name\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"doc.place.country\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"doc.place.name\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"meta.ml_ner.results.location.text\": \"${pulse_value}*\"
        }
    
    },";done)
echo -e "$pulse_body"|sed \$d >> $temp_file
unset $pulse_body
}
hashtag_func(){
    ######### hashtag option meta.hashtag.results
    if [ -z "$1" ]; then
        read -p "Paste Hashtags (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    pulse_var=${initial_var//$'\n'/}
        pulse_body=$(IFS=","
        for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"wildcard\": {
                \"username\": \"${pulse_value}*\"
            }
            },
            {
            \"wildcard\": {
                \"doc.user.screen_name\": \"${pulse_value}*\"
            }
            },";done)
    echo -e "$pulse_body"|sed \$d >> $temp_file
    unset $pulse_body
}
custom_exact(){
    pulse_body=$(IFS=","
    for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"match_phrase\": {
                \"$custom_var\": \"${pulse_value}\"
            }
            },";done)
    echo -e "$pulse_body"|sed \$d >> $temp_file
    unset $pulse_body
}
custom_wildcard(){
    pulse_body=$(IFS=","
    for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"wildcard\": {
                \"$custom_var\": \"${pulse_value}*\"
            }
            },";done);break
    echo -e "$pulse_body"|sed \$d >> $temp_file
    unset $pulse_body
}
custom_func(){
    ######### hashtag option meta.hashtag.results
    read -p "custome metadata labeel: " custom_var
    if [ -z "$1" ]; then
        read -p "Paste metadata value (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    pulse_var=${initial_var//$'\n'/}
    #prepare for loop
    

    #prompt for wildcard or not
    PS3='Please enter your choice: '
    options=("Wildcard" "Exact Match" "Quit")
    select opt in "${options[@]}";do
        case $opt in
            "Wildcard")
                custom_wildcard;break
                ;;
            "Exact Match")
                custom_exact;break
                ;;
            "Quit")
                break
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
    
        
}
header(){
    echo -e "
    {
    \"query\": {
        \"bool\": {
        \"minimum_should_match\": 1,
        \"should\": [
        " >> $temp_file
}

#print header data to temp file
header
#menu to prompt user for option
PS3='Please enter your choice: '
options=("Usernames" "Hashtags" "Locations" "Images" "Custom" "Clean Data" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Usernames")
            username_func;break
            ;;
        "Hashtags")
            hashtag_func;break
            ;;
        "Locations")
            geo_func;break
            ;;
        "Images")
            image_func;break
            ;;
        "Custom")
            custom_func;break
            ;;
        "Clean Data")
            #this will loop back into menu to allow user to do stuff with that data that is cleaned
            clean_data
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
#print out the body above minus 1 line to snip that last comma
echo -e "} 
      ]
    }
  }
}" >> $temp_file
cat $temp_file |pbcopy && echo "copied to clipboard"
rm $temp_file