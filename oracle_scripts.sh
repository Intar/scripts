#!/bin/bash
ADMIN_USER=
ADMIN_PASS=
SYS_PASSWORD=
ADD=0
DEL=0
EXP=0
FORCE=0
IMP=0
TABL=0
DATE=`date +%y.%m.%d-%H.%M.%S`
ACTION="SKIP"

function help {
echo -ne "Использование: oracle_scripts [КЛЮЧ] ...\n
Ключи:
-a добавление пользователя БД
-d удаление пользователя БД
-e экспорт пользователя БД
-u пользователь, с которым будут вестись операции добавления/удаления/импорта
-p пароль для пользователя БД
-f force режим, дает возможность удалить пользователей формата MIS_....

Для импорта:
-i импорт бэкапа
-n имя файла для импорта
-s пользователь-источник, из кого производится экспорт, также и для импорта
-w пароль от пользователя-источника

Для работы с таблицами:
-t таблицы для копирования, указываются через запятую
-x действие, которое будет выполнено при обнаружении таблицы с таким же названием (может принимать одно из 4 значений:\n
    \tSKIP - значение по умолчанию. В этом случае Oracle не трогает таблицу в схеме пользователя, на которого накатывается дамп и переходит к следующей таблице из дампа\n
    \tAPPEND - загружает записи таблицы из дампа, при этом старые записи, которые были у пользователя остаются неизмененными\n
    \tTRUNCATE - удаляет старые записи и после этого загружает записи из дампа\n
    \tREPLACE - удаляет таблицу из схемы и пересоздает ее, после этого загружает в таблицу записи из дампа\n
Невозможно указывать одновременно ключи -a и -d, для пересоздания пользователя (только для USERDB_...) необходимо указывать два ключа: -a -f.\n"
}

function add {
echo add $USERDB $PASS
echo -e "set serveroutput on\nCALL CREATE_USER('$USERDB','$PASS');" | sqlplus $ADMIN_USER/$ADMIN_PASS
}

function delete {
echo delete $USERDB
echo -e "set serveroutput on\nCALL DROP_DEVELOPER_USER_FORCE('$USERDB');" | sqlplus $ADMIN_USER/$ADMIN_PASS
}

function del_force {
echo $USERDB delete force
echo -e "set serveroutput on\nCALL DROP_MIS_USER_FORCE('$USERDB');" | sqlplus $ADMIN_USER/$ADMIN_PASS
}

function export_user {
expdp ${FUSER}/${PASS_FROM} DIRECTORY=DATA_PUMP_DIR DUMPFILE=${FUSER}_${DATE}.dmp exclude=statistics
}

function import_user {
TYPES="CREATE OR REPLACE TYPE \"STRINGSTABLE\" AS TABLE OF VARCHAR2(256);\n
/\n
CREATE OR REPLACE TYPE \"NUMBERSTABLE\" AS TABLE OF NUMBER(19,0);\n
/\n
UPDATE \"schema_version\" set \"installed_by\" = '$USERDB';\n
/\n
COMMIT;\n"
impdp ${USERDB}/${PASS} REMAP_SCHEMA=${FUSER}:${USERDB} DIRECTORY=DATA_PUMP_DIR DUMPFILE=${DUMPFILENAME}
echo -e "${TYPES}" | sqlplus "${USERDB}"/"${PASS}"
}

function export_table {
expdp ${FUSER}/${PASS_FROM} DIRECTORY=DATA_PUMP_DIR DUMPFILE=${FUSER}_tables_${DATE}.dmp TABLES=${TABLES}
}

function import_table {
impdp ${USERDB}/${PASS} REMAP_SCHEMA=${FUSER}:${USERDB} DIRECTORY=DATA_PUMP_DIR DUMPFILE=${DUMPFILENAME} TABLE_EXISTS_ACTION=${ACTION}
}


if [ $# -eq "0" ] || [ $# -eq "1" ] || [ $# -eq "2" ]
then
    help
    exit 1
fi

while getopts ":adeifu::p::s::t::n::w::x:" opt; do
    case $opt in
	a ) 
	    ADD=1;;
	d )
	    DEL=1;;
	e )
	    EXP=1;;
	f )
	    FORCE=1;;
	i )
	    IMP=1;;
	    
	u )
	    USERDB=${OPTARG}
	    ;;
	p )
	    PASS=${OPTARG}
	    ;;
	s )
	    FUSER=${OPTARG};;
	t )
	    TABL=1
	    TABLES=${OPTARG};;
	n )
	    DUMPFILENAME=${OPTARG};;
	w )
	    PASS_FROM=${OPTARG};;
	x )
	    ACTION=${OPTARG};;
	
	* )
	    echo "Неверный аргумент"
	    help
	    break
	    ;;
    esac
done
shift $((OPTIND-1))

if [ "$ADD" = "0" -a "$DEL" = "0" -a "$EXP" = "0" -a "$IMP" = "0" ];then
	echo "Неверно указаны ключи запуска скрипта"
	exit 2
fi

if [ "$ADD" = "1" -a "$DEL" = "1" ]; then
			echo "Неверно указаны ключи запуска скрипта"
			exit 2
			elif [ "$ADD" = "1" -a "$EXP" = "1" ]; then
				echo "Неверно указаны ключи запуска скрипта"
				exit 2
			elif [ "$DEL" = "1" -a "$EXP" = "1" ]; then
				echo "Неверно указаны ключи запуска скрипта"
				exit 2
fi


if [ "$ADD" = "1" -a "$FORCE" = "0" ];then
			add $USERDB $PASS
			exit 0
		    else
			if [ "$ADD" = "1" -a "$FORCE" = "1" ]; then
				delete $USERDB
				add $USERDB $PASS
				echo $USERDB add force
				exit 0
			fi
fi

if [ "$DEL" = "1" -a "$FORCE" = "0" ];then
		delete $USER
		exit 0
		elif [ "$DEL" = "1" -a "$FORCE" = "1" ]; then
		    del_force $USER
		    exit 0
fi

if [ "$EXP" = "1" -a "$IMP" = "1" -a "$TABL" = "0" ];then
		export_user $FUSER $PASS_FROM
		del_force $USERDB
		add $USERDB $PASS
		DUMPFILENAME=${FUSER}_${DATE}.dmp
		import_user $USERDB $PASS $FUSER $DUMPFILENAME
		rm /home/oracle/dpdump/$DUMPFILENAME
		exit 0
		elif [ "$EXP" = "1" -a "$IMP" = "1" -a "$TABL" = "1" ];then
			export_table $FUSER $PASS_FROM $TABLES
			DUMPFILENAME=${FUSER}_tables_${DATE}.dmp
			import_table $USERDB $PASS $FUSER $DUMPFILENAME $ACTION
			rm /home/oracle/dpdump/$DUMPFILENAME
			exit 0
fi

if [ "$EXP" = "1" -a "$TABL" = "0" ];then
	    export_user $FUSER $PASS_FROM
	    exit 0
	    elif [ "$EXP" = "1" -a "$TABL" = "1" ];then
		export_table $FUSER $PASS_FROM $TABLES
	    exit 0
fi

if [ "$IMP" = "1" -a "$TABL" = "0" ];then
	    import_user $USERDB $PASS $FUSER $DUMPFILENAME
	    exit 0
fi