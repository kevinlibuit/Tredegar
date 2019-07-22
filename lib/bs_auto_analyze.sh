#!/bin/bash

#author: Kevin Libuit, Erin Young
#email: kevin.libuit@dgs.virginia.gov


#----#----#----#----#----#----#----#----#----#----

USAGE="
This BASH script is meant to run in the background and initiate a
Tredegar run on newly created BaseSpace Projects

./bs_auto_analyze.sh <basemount_dir> 

If projects exist in your current <basemount_dir> that need to be analyzed, add them as a second argument in a comma
separated list, e.g. 

./bs_auto_analyze.sh <basemount_dir> proj1,proj2,proj3

"

#----#----#----#----#----#----#----#----#----#----

basemount_dir=$1
output_dir=pwd

# ensure basemount_dir exists
if [ -z "${basemount_dir}" ]
then
  echo $USAGE
  exit
fi

# try to refresh basemount_dir, remount if error
if [ -n "$(basemount-cmd --path ${basemount_dir}/Projects refresh | grep Error)" ]
then
  yes | basemount --unmount $basemount_dir
  basemount $basemount_dir
fi

# Create current bs_projects.log
echo Project screening initiated $(date) >> ./bs_projects.log
for p in ${basemount_dir}/Projects/*
do
    project=$(echo $p| awk -F'/' '{print $NF}')
    if grep -wq "${project}" ./bs_projects.log
    then
        :
    else
        echo $project >> ./bs_projects.log
    fi
done

# Add specified projects to projects_to_analyze.log
touch ./projects_to_analyze.log
for p in $(echo $2 | sed "s/,/ /g")
do
    if ! grep -wq "${p}" ./projects_to_analyze.log
    then
        echo $p >> ./projects_to_analyze.log
    fi
done

while [ -d "${basemount_dir}/Projects" ]
do
    # Search bs_proj dir against bs_projects.log to identify new projects; add new projects to projects_to_analyze.log
    for p in ${basemount_dir}/Projects/*
    do
        project=$(echo $p| awk -F'/' '{print $NF}')
        if grep -wq "${project}" ./bs_projects.log
        then
            :
        else
            if ! grep -wq "${project}" ./projects_to_analyze.log
            then
                echo $project >> ./projects_to_analyze.log
            fi
        fi
    done

    # If reads exist in the new projects, do a task on new proj, add proj to bs_projects.log and remove it from projects_to_analyze.log
    if [ -s "./projects_to_analyze.log" ]
    then
        for p in $(cat ./projects_to_analyze.log)
        do
            test_file=$(timeout -k 2m 1m find ${basemount_dir}/Projects/${p}/Samples/ -iname *fastq.gz | head -n 1 )
            if [ -z "$test_file" ]
            then
                echo "Fastq files not found in ${basemount_dir}/Projects/${p}/Samples/ $(date)"
            else
                echo "Running Tredegar on ${p}"
                tredegar.py ${basemount_dir}/Projects/${p} -o ./${p}
                if [ ! -n ${basemount_dir}/Projects/${p}/AppResults/Tredegar}
		then 
		    mkdir ${basemount_dir}/Projects/${p}/AppResults/Tredegar
	    	fi
		cp ./${p}/reports/*tredegar_report.csv ${basemount_dir}/Projects/${p}/AppResults/Tredegar/
                cd ${basemount_dir}/Projects/${p}/AppResults/Tredegar/ && basemount-cmd mark-as-complete
                cd $output_dir

                if ! grep -wq "${p}" ./bs_projects.log
                then
                    echo "${p} added $(date)" >> ./bs_projects.log
                fi
                
                echo "sed -i '/"${p}"/d' ./projects_to_analyze.log" | sh
            fi
        done
    fi

    # Try refreshing the basemount project dir; remount if error
    if [ -n "$(basemount-cmd --path ${basemount_dir}/Projects/ refresh | grep Error)" ]
    then
        yes | basemount --unmount ${basemount_dir}
        basemount ${basemount_dir}
        echo "Basemount directory ${basemount_dir} remounted $(date)"
    else
        echo "Basemount directory ${basemount_dir} refreshed $(date)"
    fi

    sleep 30m
done
