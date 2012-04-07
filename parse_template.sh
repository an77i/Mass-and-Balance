#!/bin/bash
#
# template-file aircraft.specs [output_dir]
#

debug=0

export LC_CTYPE=C


if [ $# -lt 2 ] ; then
    echo "Usage $0 template aircraft.specs [output_dir]";
    exit 1;
fi

if [ ! -f $1 ]; then
    echo "template file: $1 - not found.";
    exit 1;
fi

if [ ! -f $2 ]; then
    echo "specs file: $2 - not found.";
    exit 1;

fi

TEMPLATE_FILE="$1"
SPECS_FILE_PATH="$2"
OUTPUT_DIR=""

if [ ! -z $3 ]; then
    OUTPUT_DIR=$3
fi

SPEC_BASE=$(basename $SPECS_FILE_PATH)
SPEC_FILE=${SPEC_BASE%.*}
SPEC_EXT=${SPEC_BASE##*.}

if [ z"$SPEC_EXT" != "zspecs" ]; then
    echo "Spec file must have .specs extension ($SPEC_EXT)"
    exit 1
fi

if [ ! -z "$OUTPUT_DIR" ]; then
    OUTPUT_FILE="$OUTPUT_DIR/$SPEC_FILE.html"
else
    OUTPUT_FILE="$SPEC_FILE.html"
fi

echo "Handling file: $SPECS_FILE_PATH"

# load point creation
source ./create_lp.sh

# row creation
source ./create_row.sh

function simple_replace()
{
    if [ $# -ne 2 ]; then
	echo $FUNCNAME needs 2 parameters
	exit 1
    fi

    local a=$1
    local b=$2

    if [[ -z $a ]] || [[ -z $b ]]; then
	echo $FUNCNAME got zero length string
	exit 1
    fi

    if [ $debug -ne 0 ]; then
	echo "Replacing: /$a/ with /$b/"
    fi
    perl -i -pe 'BEGIN{undef $/;} s�/\*'$a'\*/.*?/\*\*/�'"$b"'�smg' $OUTPUT_FILE
}

# the modifications will be done on the output file
cp $TEMPLATE_FILE $OUTPUT_FILE

code_output=""
variable_names=""
saveables_group=""
saveable_group_values=""
extra_masses=""

while read i; do
    if [[ "${i:0:1}" != "#" ]] && [[ "${i:0:1}" != " " ]] && [[ "${i:0:1}" != '' ]]; then

	name=`echo "$i" | cut -f 1 -d =`
	value=`echo "$i" | cut -f 2- -d =`

	if [ z"$name" == z"LOAD_POINT" ]; then
	    create_lp $value

	    variable_names="$variable_names$g_name\n"
	    code_output="$code_output"$(echo $g_code_line | sed -e "s/#/ /g")"\n"

	    if [ "${value:0:5}" == "LP_I_" ] || [ "${value:0:5}" == "LP_F_" ] || [ "${value:0:5}" == "LP_C_" ]; then
		saveables_group="$saveables_group$g_saveable_group\n"
		saveable_group_values="$saveable_group_values$g_saveable_group_value\n"
	    fi
	    create_row $value
	    code_output="$code_output$g_code_line\n"
	    if [ ! -z $g_extra_mass ]; then
		extra_masses="$extra_masses $g_extra_mass"
	    fi
	else
	    simple_replace "$name" "$value"
	fi

   fi
done < $SPECS_FILE_PATH

simple_replace "REPLACE_TABLE_ROWS" "$code_output"

for i in `echo -e $variable_names | sed -e "s/\\n/ /g"`; do
    simple_replace "$i" "$i"
done

simple_replace "SAVEABLES" "$saveables_group"
simple_replace "SAVEABLE_VALUES" "$saveable_group_values"

extra_calc_mass=""
extra_mass_calc_moments=""
extra_mass_moments=""
extra_debug_lines=""

create_extra_mass()
{
    for i in $*; do
	extra_calc_mass="$extra_calc_mass$i,\n"
	extra_mass_calc_moments="${extra_mass_calc_moments}calc_moment($i);\n"
	extra_mass_moments="$extra_mass_moments$i.moment +\n"
	extra_debug_lines="${extra_debug_lines}debug.textContent += (\" \" + $i.moment.toFixed(3));\n"
    done
}


if [ "z" != z"$extra_masses" ]; then 
    create_extra_mass "$extra_masses"

    simple_replace "EXTRA_CALC_MASS" "$extra_calc_mass"
    simple_replace "EXTRA_MASS_CALC_MOMENTS" "$extra_mass_calc_moments"
    simple_replace "EXTRA_MASS_MOMENTS" "$extra_mass_moments"
    simple_replace "EXTRA_DEBUG" "$extra_debug_lines"
fi

echo "Output file is: $OUTPUT_FILE"

exit 0
