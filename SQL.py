import psycopg2
from psycopg2.extensions import AsIs

conn = psycopg2.connect(dbname='postgres', user='postgres', password='12345', host='localhost',  options="-c search_path=schema_kurs,public")

def Tables():
    
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM pg_catalog.pg_tables")
    tables = []
    for x in cursor.fetchall():
        if x[0]=='schema_kurs':
            tables += [x[1]]
    cursor.close()  
    return tables

def Column_Headers(choice_table):
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM %(table)s", {"table": AsIs(choice_table)})
    column_names = [desc[0] for desc in cursor.description]
    cursor.close()  
    return column_names

def Table_Data(choice_table):
    data = []
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM %(table)s", {"table": AsIs(choice_table)})
    for row in cursor.fetchall():
        row = list(row)
        data += [row]
    cursor.close()  
    return data

def Add(choice_table, values):
    column_names = tuple(Column_Headers(choice_table))
    columns = ', '.join(column_names)
    param_placeholders = ','.join(['%s' for x in range(len(values))])
    sql = f"INSERT INTO  {choice_table} ({columns}) VALUES ({param_placeholders})" 
    values = values.items()
    param_values = tuple(x[1] for x in values)
    cursor = conn.cursor()
    try:
        cursor.execute(sql, param_values)
    except BaseException:
        conn.rollback()
        return("error")
    conn.commit()
    cursor.close() 
   

def Find(choice_table, values):
    values['-LISTBOX-'] = values['-LISTBOX-'][0]
    sql = f"""SELECT * FROM {choice_table} 
            WHERE {values['-LISTBOX-']} = '{values['-INPUT-']}'"""
    values = values.items()
    param_values = tuple(x[1] for x in values)
    data = []

    cursor = conn.cursor()
    try:
        cursor.execute(sql, param_values)
        for row in cursor.fetchall():
            row = list(row)
            data += [row]
        print(data)
    except BaseException:
        conn.rollback()
        return("error")
    conn.commit()
    cursor.close() 
    return data

def Change(choice_table, values, id):
    primary_key = Find_primary_key(choice_table)
    sql = f"""UPDATE {choice_table} SET {values["-COMBO-"]} = '{values["-INPUT-"]}'
                WHERE {primary_key} = '{id}'"""
   
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
        print(cursor.fetchall)
    except BaseException:
        conn.rollback()
        return("error")
    conn.commit()
    cursor.close() 

def Delete(choice_table, id):
    primary_key = Find_primary_key(choice_table)

    sql = f"""DELETE FROM {choice_table}
                WHERE {primary_key} = '{id}'"""
    
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
    except BaseException:
        #rollback the previous transaction before starting another
        conn.rollback()
        return("error")
    conn.commit()
    cursor.close() 



def Find_primary_key(choice_table):
    cursor = conn.cursor()
    sql = f"""SELECT column_name
    FROM information_schema.table_constraints
        JOIN information_schema.key_column_usage
            USING (constraint_catalog, constraint_schema, constraint_name,
                    table_catalog, table_schema, table_name)
    WHERE constraint_type = 'PRIMARY KEY'
    AND (table_schema, table_name) = ('schema_kurs', '{choice_table}')
    ORDER BY ordinal_position;"""
    
    cursor.execute(sql)
    rows = cursor.fetchall()
    if rows == []:
        return rows
    else:
        primary_key = rows[0][0]
        return primary_key
    

def count_group_on_course():
    cursor = conn.cursor()
    cursor.execute("""SELECT  course.course_name, COUNT(training_group.number_group)
                    FROM training_group
                    INNER JOIN course ON training_group.course_code = course.course_code
                    GROUP BY course.course_name
                    """)
    data = []
    for row in cursor.fetchall():
        row = list(row)
        data += [row]
    cursor.close()  
    return data



def students_on_course():
    cursor = conn.cursor()
    cursor.execute("""SELECT  course.course_name, COUNT(student.number_student), SUM (course.course_cost)
                    FROM student
                    INNER JOIN training_group ON student.number_group = training_group.number_group
                    INNER JOIN course ON training_group.course_code = course.course_code
                    GROUP BY course.course_name
                    """)

    data = []
    for row in cursor.fetchall():
        row = list(row)
        data += [row]
    cursor.close()  
    return data

def number_students_at_teacher():
    cursor = conn.cursor()
    cursor.execute("""select educator.full_name_educator, COUNT(distinct student.number_student) 
	FROM student
	INNER JOIN training_group ON student.number_group = training_group.number_group
	inner join timetable on training_group.number_group = timetable.number_group
	inner join educator on timetable.employee_number = educator.employee_number
	GROUP BY educator.full_name_educator """)

    data = []
    for row in cursor.fetchall():
        row = list(row)
        data += [row]
    cursor.close()  
    return data


def extended_timetable():
    cursor = conn.cursor()
    cursor.execute("""SELECT timetable.number_group, educator.full_name_educator, timetable.number_week, days.name_day, pairs.number_pairs, pairs.start_pairs, pairs.end_pairs
                    FROM timetable
                    INNER JOIN pairs ON pairs.number_pairs = timetable.number_pairs
                    INNER JOIN days ON days.number_day = timetable.number_day
                    INNER JOIN educator ON educator.employee_number = timetable.employee_number
                    WHERE timetable.number_group = '101'
                    ORDER BY days.number_day 
                    """)

    data = []
    for row in cursor.fetchall():
        row = list(row)
        data += [row]
    cursor.close()  
    return data