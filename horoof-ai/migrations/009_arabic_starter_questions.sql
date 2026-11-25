-- Public starter content; it should receive independent educational review before production.
WITH starter AS (
 INSERT INTO horoof.subjects(owner_id,name,description)
 SELECT NULL,'Arabic General Knowledge','Starter questions for the Arabic letter board; please review educational content before production.'
 WHERE NOT EXISTS (SELECT 1 FROM horoof.subjects WHERE owner_id IS NULL AND name='Arabic General Knowledge') RETURNING id
), questions(letter,question,answer) AS (VALUES
('ا','ما اسم الكوكب الذي نعيش عليه؟','الأرض'),
('ب','ما اسم المدينة الفرنسية المعروفة ببرج إيفل؟','باريس'),
('ت','ما الفاكهة الحمراء أو الخضراء التي تنمو على الأشجار؟','تفاح'),
('ث','ما الحيوان المعروف بالمكر وله ذيل كثيف؟','ثعلب'),
('ج','ما الحيوان المعروف بسفينة الصحراء؟','جمل'),
('ح','ما الحيوان المخطط بالأبيض والأسود؟','حمار وحشي'),
('خ','ما الخضار الأخضر الطويل المستخدم في السلطة؟','خيار'),
('د','ما الحيوان الذي يبيض ويصدر صوت القوقأة؟','دجاجة'),
('ذ','ما المعدن النفيس الأصفر؟','ذهب'),
('ر','ما الفصل الذي تتفتح فيه الأزهار؟','ربيع'),
('ز','ما الزهرة التي تشير غالباً إلى الحب؟','زهرة'),
('س','ما المادة الحلوة التي تُضاف عادة إلى الشاي؟','سكر'),
('ش','ما النجم الذي يضيء الأرض نهاراً؟','شمس'),
('ص','ما الطائر الجارح المعروف بحدة البصر؟','صقر'),
('ض','ما الذي يصدر عن المصباح وينير المكان؟','ضوء'),
('ط','ما الكائن الذي يطير وله ريش؟','طائر'),
('ظ','ما غياب الضوء؟','ظلام'),
('ع','ما العضو المسؤول عن الإبصار؟','عين'),
('غ','ما الحيوان الرشيق ذو القرون؟','غزال'),
('ف','ما اسم الحيوان الكبير صاحب الخرطوم؟','فيل'),
('ق','ما التابع الطبيعي للأرض؟','قمر'),
('ك','ما الحيوان الأليف الذي ينبح؟','كلب'),
('ل','ما السائل الأبيض الذي تنتجه الأبقار؟','لبن'),
('م','ما السائل الضروري للحياة؟','ماء'),
('ن','ما الجسم المضيء في السماء ليلاً؟','نجم'),
('ه','ما الاسم الذي يطلق على تساقط المطر من السحب؟','هطول'),
('و','ما الزهرة ذات الرائحة الجميلة؟','وردة'),
('ي','ما اسم اليوم الذي يأتي بعد السبت؟','يوم الأحد')
)
INSERT INTO horoof.questions(subject_id,letter,question,answer,language,review_status)
SELECT starter.id,q.letter,q.question,q.answer,'ar','approved' FROM starter CROSS JOIN questions q WHERE left(q.answer,1)=q.letter;
