#!/bin/bash

# Beispiel Ausführung: ./execution.sh HelloWorld Addition CurrentDate -- bash functions.csv

# Überprüfen der Argumente
if [ $# -lt 3 ]; then
    echo "Verwendung: $0 <funktion1> [funktion2] ... -- <sprache> <csv_datei>"
    exit 1
fi

# Finden des Index von "--"
for ((i=1; i<=$#; i++)); do
    if [ "${!i}" == "--" ]; then
        separator_index=$i
        break
    fi
done

# Überprüfen, ob "--" gefunden wurde
if [ -z "$separator_index" ]; then
    echo "Bitte verwenden Sie '--' um Funktionen von Sprache und Dateinamen zu trennen."
    exit 1
fi

# Extrahieren der Funktionen, Sprache und Dateiname
functions=("${@:1:$separator_index-1}")
language="${@:$separator_index+1:1}"
csv_file="${@:$separator_index+2:1}"

# Überprüfen, ob die Datei existiert
if [ ! -f "$csv_file" ]; then
    echo "Die Datei $csv_file existiert nicht."
    exit 1
fi

# Überprüfen der Sprache
if [ "$language" != "bash" ] && [ "$language" != "python" ] && [ "$language" != "java" ]; then
    echo "Unbekannte Sprache: $language. Bitte 'bash', 'python' oder 'java' verwenden."
    exit 1
fi

# Lesen der CSV-Datei
while IFS=',' read -r name bash_func python_func java_func
do
    # Überprüfen, ob die aktuelle Funktion ausgeführt werden soll
    if [[ " ${functions[@]} " =~ " ${name} " ]] || [ ${#functions[@]} -eq 0 ]; then
        echo "Ausführung der Funktion: $name"
        
        case $language in
            "bash")
                echo "Bash-Ausgabe:"
                eval "$bash_func"
                ;;
            "python")
                echo "Python-Ausgabe:"
                python3 -c "$python_func"
                ;;
            "java")
                echo "Java-Ausgabe:"
                # Entferne Escaping von doppelten Anführungszeichen
                java_func=$(echo "$java_func" | sed 's/\\"/"/g')
                # Extrahiere imports
                imports=$(echo "$java_func" | grep -o 'import [^;]*;')
                # Entferne imports aus dem Hauptcode
                main_code=$(echo "$java_func" | sed 's/import [^;]*;//g')
                # Erstelle die Java-Datei
                echo "
                $imports
                public class TempJava {
                    public static void main(String[] args) {
                        $main_code
                    }
                }" > TempJava.java
                javac TempJava.java
                if [ $? -eq 0 ]; then
                    java TempJava
                else
                    echo "Kompilierungsfehler"
                    cat TempJava.java
                fi
                rm TempJava.java TempJava.class 2>/dev/null
                ;;
        esac
        
        echo "------------------------"
    fi
done < "$csv_file"
