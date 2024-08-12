DO $$ 
DECLARE 
    current_table text; 
    count integer;
BEGIN 
    FOR current_table IN 
        (SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name LIKE '%lock%') 
    LOOP
        EXECUTE format('
            SELECT COUNT(*) 
            FROM %I 
            WHERE locked IS TRUE', current_table) INTO count;

        IF count > 0 THEN
            RAISE NOTICE 'Table % has % rows where locked is TRUE', current_table, count;
        END IF;
    END LOOP; 
END $$;
