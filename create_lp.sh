#!/bin/bash

# External variables
g_code_line=""
g_saveable=""
g_saveable_value=""
g_nonsaveable=""

# name     translation       unit def min max mom   [step]
#
# LP_N_BEW "English" "Suomi" "kg" 0   0   -1  1.923  0.1
#
# LP_I_xxx = interactive load point, declares a saveable variable
# LP_F_xxx = interactive fuel flow row
# LP_R_xxx = non-interactive load point with result and value cells reversed
# LP_N_xxx = non-interactive load point

function create_lp()
{
    if [ $# -lt 8 ]; then
	echo "$FUNCNAME called with $*"
	exit 1
    fi

    local lpname=$1
    local lang_en=$2
    local lang_fi=$3
    local unit=$4
    local unit_def=$5
    local unit_min=$6
    local unit_max=$7
    local mom=$8
    local steps=""

    if [ $# -eq 9 ]; then
	steps=$9
    fi

    local save_item=""
    if [ "${lpname:0:5}" == "LP_I_" ] || [ "${lpname:0:5}" == "LP_F_" ]; then
	save_item=".s"
    fi

    # Whatever comes after the first 5 chars
    local the_name="${lpname:5}"

    g_code_line=""

    g_code_line="${lpname}=new l_point(\"${lpname}\","
    g_code_line="$g_code_line [$lang_en, $lang_fi],"
    g_code_line="$g_code_line ${unit},"

    # For non-interactive elements put the default value in place.
    # For interactive values put the saveable name in place.
    if [ "${lpname:0:5}" == "LP_N_" ] || [ "${lpname:0:5}" == "LP_R_" ]; then
	g_code_line="$g_code_line ${unit_def},"
    else
	g_code_line="$g_code_line g_defs${save_item}.${the_name},"
    fi

    g_code_line="$g_code_line ${unit_min}, ${unit_max}, ${mom}"

    if [ ! -z ${steps} ]; then
	g_code_line="$g_code_line, $steps"
    fi

    g_code_line="$g_code_line);"

    if [ "${lpname:0:5}" == "LP_F_" ]; then
	# fuel flow row
	g_code_line="$g_code_line ${lpname}.fuel_flow = true;"
    fi

    g_saveable="$the_name : ${unit_def},"
    g_saveable_value="$the_name.vu.get_si(),"
    g_nonsaveable="$the_name"
}

#create_lp LP_N_BEW "English" "Suomi" "kg" 0 0 -1  1.923 0.1
#echo $g_code_line

