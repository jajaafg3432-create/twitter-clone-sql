-- ============================================
-- مشروع محاكاة قاعدة بيانات تويتر
-- ER Diagram موجود في ملف README.md
-- ============================================

-- 1) إنشاء قاعدة البيانات
CREATE DATABASE IF NOT EXISTS twitter_clone;
USE twitter_clone;


-- ============================================
-- 2) إنشاء الجداول مع العلاقات (Foreign Keys)
-- ============================================

-- جدول بيانات المستخدمين الأساسية
CREATE TABLE users (
    user_id    INT AUTO_INCREMENT PRIMARY KEY,
    email      VARCHAR(100) NOT NULL UNIQUE,
    password   BINARY(64)   NOT NULL,          -- يتم تشفيره بـ MD5 عند الإدخال
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- جدول الملف الشخصي (علاقة واحد لواحد مع users)
CREATE TABLE profiles (
    profile_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    username   VARCHAR(50) NOT NULL UNIQUE,
    bio        VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- جدول التغريدات (علاقة واحد لمتعدد مع users)
CREATE TABLE tweets (
    tweet_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    content    VARCHAR(280) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- جدول المتابعة (علاقة متعدد لمتعدد بين المستخدمين أنفسهم)
CREATE TABLE follows (
    follower_id INT NOT NULL,
    followed_id INT NOT NULL,
    followed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followed_id),
    FOREIGN KEY (follower_id) REFERENCES users(user_id),
    FOREIGN KEY (followed_id) REFERENCES users(user_id)
);

-- جدول الإعجاب بالتغريدات (علاقة متعدد لمتعدد بين users و tweets)
CREATE TABLE likes (
    user_id  INT NOT NULL,
    tweet_id INT NOT NULL,
    liked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, tweet_id),
    FOREIGN KEY (user_id)  REFERENCES users(user_id),
    FOREIGN KEY (tweet_id) REFERENCES tweets(tweet_id)
);


-- ============================================
-- 3) Procedure: createAccount
-- يستقبل بيانات المستخدم والملف الشخصي ويضيفها للجدولين
-- ============================================
DELIMITER //

CREATE PROCEDURE createAccount (
    IN p_email    VARCHAR(100),
    IN p_password VARCHAR(100),
    IN p_username VARCHAR(50),
    IN p_bio      VARCHAR(255)
)
BEGIN
    DECLARE new_user_id INT;

    -- إضافة المستخدم مع تشفير الرقم السري باستخدام MD5
    INSERT INTO users (email, password)
    VALUES (p_email, MD5(p_password));

    SET new_user_id = LAST_INSERT_ID();

    -- إضافة الملف الشخصي المرتبط بنفس المستخدم
    INSERT INTO profiles (user_id, username, bio)
    VALUES (new_user_id, p_username, p_bio);
END //

DELIMITER ;


-- ============================================
-- 4) Procedure: User_Follow
-- يستقبل اسم المستخدم واسم المستخدم المراد متابعته
-- ويبحث عن الأرقام التسلسلية ويضيفها لجدول follows
-- ============================================
DELIMITER //

CREATE PROCEDURE User_Follow (
    IN p_follower_username VARCHAR(50),
    IN p_followed_username VARCHAR(50)
)
BEGIN
    DECLARE v_follower_id INT;
    DECLARE v_followed_id INT;

    SELECT user_id INTO v_follower_id
    FROM profiles
    WHERE username = p_follower_username;

    SELECT user_id INTO v_followed_id
    FROM profiles
    WHERE username = p_followed_username;

    INSERT INTO follows (follower_id, followed_id)
    VALUES (v_follower_id, v_followed_id);
END //

DELIMITER ;


-- ============================================
-- 5) تعبئة الجداول بالبيانات التجريبية
-- ============================================

-- إنشاء حسابات باستخدام createAccount
CALL createAccount('abdullah@example.com', 'pass123', 'abdullah_q', 'مطور برمجيات');
CALL createAccount('fatimah@example.com', 'pass456', 'fatimah_a',  'طالبة جامعية');
CALL createAccount('sultan@example.com',  'pass789', 'sultan_h',   'مصمم جرافيك');
CALL createAccount('maryam@example.com',  'pass321', 'maryam_k',   'كاتبة محتوى');

-- ربط المتابعة باستخدام User_Follow
CALL User_Follow('abdullah_q', 'fatimah_a');
CALL User_Follow('abdullah_q', 'sultan_h');
CALL User_Follow('fatimah_a',  'maryam_k');
CALL User_Follow('sultan_h',   'abdullah_q');

-- إضافة تغريدات
INSERT INTO tweets (user_id, content) VALUES
(1, 'أول تغريدة لي على المنصة!'),
(1, 'أتعلم SQL هذه الأيام.'),
(2, 'يوم جميل للدراسة.'),
(3, 'شاركت تصميم جديد اليوم.'),
(4, 'مقال جديد عن الكتابة الإبداعية.');

-- إضافة إعجابات
INSERT INTO likes (user_id, tweet_id) VALUES
(2, 1),
(3, 1),
(4, 2),
(1, 3),
(2, 4);


-- ============================================
-- 6) عرض البيانات
-- ============================================
SELECT * FROM users;
SELECT * FROM profiles;
SELECT * FROM tweets;
SELECT * FROM follows;
SELECT * FROM likes;


-- ============================================
-- 7) عرض عدد التغريدات لمستخدم واحد فقط
-- ============================================
SELECT p.username, COUNT(t.tweet_id) AS tweet_count
FROM tweets t
JOIN profiles p ON t.user_id = p.user_id
WHERE p.username = 'abdullah_q'
GROUP BY p.username;
