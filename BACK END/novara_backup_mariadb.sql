-- MySQL dump 10.13  Distrib 8.4.3, for Win64 (x86_64)
--
-- Host: localhost    Database: novara
-- ------------------------------------------------------
-- Server version	8.4.3

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `deliveries`
--

DROP TABLE IF EXISTS `deliveries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deliveries` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `orderId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `deliveryPersonId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `status` enum('unassigned','assigned','accepted','picked_up','delivered','failed','delayed') DEFAULT 'unassigned',
  `isDelayed` tinyint(1) DEFAULT '0',
  `delayReason` text,
  `pickupAddress` text,
  `dropoffAddress` text NOT NULL,
  `assignedAt` datetime DEFAULT NULL,
  `deliveredAt` datetime DEFAULT NULL,
  `confirmedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `orderId` (`orderId`),
  KEY `deliveryPersonId` (`deliveryPersonId`),
  CONSTRAINT `deliveries_ibfk_1` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_10` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_11` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_12` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_13` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_14` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_15` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_16` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_17` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_18` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_19` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_2` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_20` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_21` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_22` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_23` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_24` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_25` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_26` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_27` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_28` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_29` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_3` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_30` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_31` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_32` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_33` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_34` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_35` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_36` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_37` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_38` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_39` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_4` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_40` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_41` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_42` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_43` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_44` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_45` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_46` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_47` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_48` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_49` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_5` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_50` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_51` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_52` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_53` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_54` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_55` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_56` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_6` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_7` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_8` FOREIGN KEY (`deliveryPersonId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `deliveries_ibfk_9` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deliveries`
--

LOCK TABLES `deliveries` WRITE;
/*!40000 ALTER TABLE `deliveries` DISABLE KEYS */;
INSERT INTO `deliveries` VALUES ('1ada840e-6a44-4af8-9e5f-1446a5b53443','370ecde2-8c5d-48fc-a4f4-d6660f176c95','4dff29fc-1b4f-442d-9beb-33b0ed632d80','delivered',0,NULL,NULL,'awae','2026-09-16 00:38:34','2026-09-16 00:42:12','2026-09-16 00:42:12','2026-09-12 17:52:10','2026-09-16 00:42:12'),('39994906-8018-483c-ae3f-c7ca0a3f5cc8','c51030ba-6b25-4a6a-acf9-056ac5ea4c23',NULL,'unassigned',0,NULL,NULL,'awae',NULL,NULL,NULL,'2026-09-16 00:27:22','2026-09-16 00:27:22'),('86133161-0c2f-4f38-8ba2-f326415a1cec','5b68d76f-ada0-43a1-ab4c-52d5edb19351',NULL,'unassigned',0,NULL,NULL,'abang',NULL,NULL,NULL,'2026-09-14 10:43:47','2026-09-14 10:43:47'),('a7a9aad3-f46a-4adc-a34f-ec93507066e2','b52bb707-5c33-4496-8de2-85a4cae483c6',NULL,'unassigned',0,NULL,NULL,'awae',NULL,NULL,NULL,'2026-09-16 00:26:28','2026-09-16 00:26:28');
/*!40000 ALTER TABLE `deliveries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `devices`
--

DROP TABLE IF EXISTS `devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `devices` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `deviceSerial` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(255) DEFAULT 'ESP32',
  `status` enum('active','inactive','maintenance') DEFAULT 'active',
  `autoMode` tinyint(1) DEFAULT '1',
  `healthStatus` enum('excellent','good','warning','critical') DEFAULT 'good',
  `farmId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `foodThreshold` float DEFAULT '20',
  `waterThreshold` float DEFAULT '20',
  `tempMin` float DEFAULT '20',
  `tempMax` float DEFAULT '32',
  `humidityMin` float DEFAULT '50',
  `humidityMax` float DEFAULT '75',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `deviceSerial` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_2` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_3` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_4` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_5` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_6` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_7` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_8` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_9` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_10` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_11` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_12` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_13` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_14` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_15` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_16` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_17` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_18` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_19` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_20` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_21` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_22` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_23` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_24` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_25` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_26` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_27` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_28` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_29` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_30` (`deviceSerial`),
  UNIQUE KEY `deviceSerial_31` (`deviceSerial`),
  KEY `farmId` (`farmId`),
  CONSTRAINT `devices_ibfk_1` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_10` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_11` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_12` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_13` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_14` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_15` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_16` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_17` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_18` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_19` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_2` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_20` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_21` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_22` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_23` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_24` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_25` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_26` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_27` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_28` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_29` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_3` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_30` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_31` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_4` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_5` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_6` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_7` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_8` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `devices_ibfk_9` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `devices`
--

LOCK TABLES `devices` WRITE;
/*!40000 ALTER TABLE `devices` DISABLE KEYS */;
INSERT INTO `devices` VALUES ('5a0ad865-b244-47f4-833f-817c691101d3','ESP32-237050','Coop #1 Main Sensor Cluster','ESP32','active',1,'good','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2',20,20,20,32,50,75,'2026-09-12 17:30:42','2026-09-16 00:28:43');
/*!40000 ALTER TABLE `devices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `farms`
--

DROP TABLE IF EXISTS `farms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `farms` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `name` varchar(255) NOT NULL,
  `location` varchar(255) NOT NULL,
  `capacity` int DEFAULT '0',
  `currentPoultryCount` int DEFAULT '0',
  `farmerId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'approved',
  `rejectionReason` text,
  `approvedAt` datetime DEFAULT NULL,
  `approvedBy` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `farmerId` (`farmerId`),
  CONSTRAINT `farms_ibfk_1` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_10` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_11` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_12` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_13` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_14` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_15` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_16` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_17` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_18` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_19` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_2` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_20` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_21` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_22` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_23` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_24` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_25` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_26` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_27` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_28` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_29` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_3` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_30` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_31` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_4` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_5` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_6` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_7` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_8` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `farms_ibfk_9` FOREIGN KEY (`farmerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `farms`
--

LOCK TABLES `farms` WRITE;
/*!40000 ALTER TABLE `farms` DISABLE KEYS */;
INSERT INTO `farms` VALUES ('1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Bobpoultry','Douala',1000,0,'37a4eb05-86ca-4bd6-8754-df24b31b4763','2026-09-12 16:57:13','2026-09-12 16:57:13','pending',NULL,NULL,NULL),('28e4a0f2-3cae-49fd-b11a-03e308ab2b46','Alima farm','yaounde',1000,0,'37a4eb05-86ca-4bd6-8754-df24b31b4763','2026-09-12 16:51:19','2026-09-12 16:51:19','pending',NULL,NULL,NULL);
/*!40000 ALTER TABLE `farms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `userId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` enum('ai_alert','environmental_alert','order_update','delivery_update','system') DEFAULT 'system',
  `isRead` tinyint(1) DEFAULT '0',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `userId` (`userId`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_10` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_11` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_12` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_13` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_14` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_15` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_16` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_17` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_18` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_19` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_2` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_20` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_21` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_22` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_23` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_24` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_25` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_26` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_27` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_28` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_3` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_4` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_5` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_6` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_7` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_8` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_ibfk_9` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES ('122bf3df-102f-43b4-ac8c-7872bf90ec42','37a4eb05-86ca-4bd6-8754-df24b31b4763','New Order Received','New order #c51030ba placed by customer for your farm products (13800 FCFA).','order_update',0,'2026-09-16 00:27:23','2026-09-16 00:27:23'),('212aeb25-0e92-4af7-b2df-9c5e8c313c4e','320aba61-9e02-4612-a59b-d2ad05ec0293','Payment Confirmed','Payment of 7500.00 FCFA for order #370ecde2 was successful via MTN Mobile Money.','order_update',0,'2026-09-12 17:52:58','2026-09-12 17:52:58'),('2ab42f3a-915e-4ca4-b456-b5b593eb9e4e','37a4eb05-86ca-4bd6-8754-df24b31b4763','Temperature Threshold Alert','Farm \'Bobpoultry\' - Device \'Coop #1 Main Sensor Cluster\' temperature is 34.5┬░C. Automated climate adjustment activated.','environmental_alert',0,'2026-09-12 17:31:45','2026-09-12 17:31:45'),('3141fdaa-0f4e-47e4-94a9-c32434930e21','b51dcf39-6755-4ecc-ab9a-cb6eafe12bdc','Payment Confirmed','Payment of 2500.00 FCFA for order #5b68d76f was successful via MTN Mobile Money.','order_update',0,'2026-09-14 10:44:12','2026-09-14 10:44:12'),('32e5ddb8-4320-4cbb-87a5-b84c1af5e630','320aba61-9e02-4612-a59b-d2ad05ec0293','Delivery Courier Assigned ≡ƒÜÜ','dev has been assigned as your delivery courier for order #370ecde2.','delivery_update',0,'2026-09-16 00:38:34','2026-09-16 00:38:34'),('414284a9-0ee3-483b-a926-e95721eadbf7','4dff29fc-1b4f-442d-9beb-33b0ed632d80','New Delivery Assigned! ≡ƒ¢╡','You have been assigned to deliver order #370ecde2 for fav - Delivery to: awae. Tap to accept.','delivery_update',0,'2026-09-16 00:38:34','2026-09-16 00:38:34'),('45f86d27-700d-46ba-a229-b59c4d477e66','7acb3d06-16d8-4718-b4ff-9164a0e3a72c','Order Status Updated','Your order #b52bb707 status is now \'accepted\'.','order_update',0,'2026-09-16 00:29:20','2026-09-16 00:29:20'),('554ffb88-8e7b-44b1-93ad-b30f39e2c998','7acb3d06-16d8-4718-b4ff-9164a0e3a72c','Payment Confirmed','Payment of 8800.00 FCFA for order #b52bb707 was successful via MTN Mobile Money.','order_update',0,'2026-09-16 00:27:44','2026-09-16 00:27:44'),('5aa10083-c864-47b1-a8ad-e12c819d0744','37a4eb05-86ca-4bd6-8754-df24b31b4763','Low Food Level Warning','Farm \'Bobpoultry\' - Device \'Coop #1 Main Sensor Cluster\' food level dropped to 15%. Automated feeding triggered.','environmental_alert',0,'2026-09-16 00:40:41','2026-09-16 00:40:41'),('7b3790b2-e197-486d-a171-d89d94190d27','37a4eb05-86ca-4bd6-8754-df24b31b4763','Temperature Threshold Alert','Farm \'Bobpoultry\' - Device \'Coop #1 Main Sensor Cluster\' temperature is 34.5┬░C. Automated climate adjustment activated.','environmental_alert',0,'2026-09-16 00:40:41','2026-09-16 00:40:41'),('91d4db06-ec75-48bb-9ef9-8cd8db80862a','37a4eb05-86ca-4bd6-8754-df24b31b4763','New Order Received','New order #b52bb707 placed by customer for your farm products (8800 FCFA).','order_update',0,'2026-09-16 00:26:28','2026-09-16 00:26:28'),('991c9170-6f38-45f4-8d7d-bcb190274841','7acb3d06-16d8-4718-b4ff-9164a0e3a72c','Payment Confirmed','Payment of 13800.00 FCFA for order #c51030ba was successful via Orange Money.','order_update',0,'2026-09-16 00:27:31','2026-09-16 00:27:31'),('a6d027e9-e358-4203-87cd-11a59cb4ba48','320aba61-9e02-4612-a59b-d2ad05ec0293','Delivery Confirmed Successful!','Your order #370ecde2 has been successfully delivered and confirmed.','delivery_update',0,'2026-09-16 00:42:12','2026-09-16 00:42:12'),('c64c4b63-9dc5-447e-bf6c-d0efc2a29cd4','320aba61-9e02-4612-a59b-d2ad05ec0293','Delivery Update','Your package for order #370ecde2 status is now \'accepted\'.','delivery_update',0,'2026-09-16 00:42:07','2026-09-16 00:42:07'),('cd6f400d-9c0d-4576-8d16-5eb3cf698884','37a4eb05-86ca-4bd6-8754-df24b31b4763','New Order Received','New order #5b68d76f placed by customer for your farm products (2500 FCFA).','order_update',0,'2026-09-14 10:43:47','2026-09-14 10:43:47'),('dfd343b1-d8f4-4828-94a2-e23cb22048b4','7acb3d06-16d8-4718-b4ff-9164a0e3a72c','Order Status Updated','Your order #c51030ba status is now \'accepted\'.','order_update',0,'2026-09-16 00:29:29','2026-09-16 00:29:29'),('e4482bd0-f4bd-4a60-9244-fbbdf19af4ed','37a4eb05-86ca-4bd6-8754-df24b31b4763','Low Food Level Warning','Farm \'Bobpoultry\' - Device \'Coop #1 Main Sensor Cluster\' food level dropped to 15%. Automated feeding triggered.','environmental_alert',0,'2026-09-12 17:31:45','2026-09-12 17:31:45'),('f660bbde-f694-4aee-8954-9a389331722a','37a4eb05-86ca-4bd6-8754-df24b31b4763','New Order Received','New order #370ecde2 placed by customer for your farm products (7500 FCFA).','order_update',0,'2026-09-12 17:52:10','2026-09-12 17:52:10');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orderitems`
--

DROP TABLE IF EXISTS `orderitems`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orderitems` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `orderId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `productId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `unitPrice` decimal(10,2) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `orderId` (`orderId`),
  KEY `productId` (`productId`),
  CONSTRAINT `orderitems_ibfk_1` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_10` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_11` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_12` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_13` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_14` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_15` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_16` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_17` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_18` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_19` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_2` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_20` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_21` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_22` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_23` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_24` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_25` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_26` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_27` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_28` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_29` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_3` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_30` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_31` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_32` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_33` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_34` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_35` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_36` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_37` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_38` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_39` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_4` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_40` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_41` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_42` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_43` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_44` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_45` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_46` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_47` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_48` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_49` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_5` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_50` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_51` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_52` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_53` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_54` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_55` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_56` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_57` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_58` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_6` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_7` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_8` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orderitems_ibfk_9` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orderitems`
--

LOCK TABLES `orderitems` WRITE;
/*!40000 ALTER TABLE `orderitems` DISABLE KEYS */;
INSERT INTO `orderitems` VALUES ('14c25b15-f1b0-47ac-8d0b-b282091da226','370ecde2-8c5d-48fc-a4f4-d6660f176c95','88dbd9ae-f55d-42d9-ad61-a0e041ac7b69',3,2500.00,'2026-09-12 17:52:10','2026-09-12 17:52:10'),('290f168a-a1d5-4b45-8562-5a9bb1cfd1eb','c51030ba-6b25-4a6a-acf9-056ac5ea4c23','2b7218ed-aee1-4c42-9442-72be7274b624',1,6000.00,'2026-09-16 00:27:22','2026-09-16 00:27:22'),('77850cae-e898-4bbc-bfbb-638e7a738e8a','b52bb707-5c33-4496-8de2-85a4cae483c6','0f448545-4483-454c-ab85-d6d1d67b5822',1,3800.00,'2026-09-16 00:26:28','2026-09-16 00:26:28'),('8dec4940-427e-49af-9401-40c115d5fab1','5b68d76f-ada0-43a1-ab4c-52d5edb19351','88dbd9ae-f55d-42d9-ad61-a0e041ac7b69',1,2500.00,'2026-09-14 10:43:47','2026-09-14 10:43:47'),('8fe998b9-2037-4c31-83e4-f5401a7f58c6','c51030ba-6b25-4a6a-acf9-056ac5ea4c23','75971f27-a90f-4870-8bbb-97328ab77b0f',1,4800.00,'2026-09-16 00:27:22','2026-09-16 00:27:22'),('9822e4b8-1a65-4bca-b57d-a972829b90ce','c51030ba-6b25-4a6a-acf9-056ac5ea4c23','ae309483-944b-49d7-a7a9-0bfe37bcdc5a',2,1500.00,'2026-09-16 00:27:22','2026-09-16 00:27:22'),('e8b5e6d8-eca8-4f3c-88a2-7b148e341218','b52bb707-5c33-4496-8de2-85a4cae483c6','23b7cff7-09e8-43a4-b600-2f26ecd04650',1,5000.00,'2026-09-16 00:26:28','2026-09-16 00:26:28');
/*!40000 ALTER TABLE `orderitems` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `customerId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `totalAmount` decimal(12,2) NOT NULL,
  `currency` varchar(255) DEFAULT 'FCFA',
  `status` enum('pending','accepted','rejected','in_transit','delivered','cancelled') DEFAULT 'pending',
  `paymentStatus` enum('pending','paid','failed') DEFAULT 'pending',
  `paymentMethod` varchar(255) DEFAULT NULL,
  `shippingAddress` text NOT NULL,
  `notes` text,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `customerId` (`customerId`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_10` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_11` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_12` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_13` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_14` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_15` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_16` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_17` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_18` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_19` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_20` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_21` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_22` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_23` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_24` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_25` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_26` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_27` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_28` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_29` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_30` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_4` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_5` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_6` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_7` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_8` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `orders_ibfk_9` FOREIGN KEY (`customerId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES ('370ecde2-8c5d-48fc-a4f4-d6660f176c95','320aba61-9e02-4612-a59b-d2ad05ec0293',7500.00,'FCFA','delivered','paid','MTN Mobile Money','awae',NULL,'2026-09-12 17:52:10','2026-09-16 00:42:12'),('5b68d76f-ada0-43a1-ab4c-52d5edb19351','b51dcf39-6755-4ecc-ab9a-cb6eafe12bdc',2500.00,'FCFA','pending','paid','MTN Mobile Money','abang',NULL,'2026-09-14 10:43:47','2026-09-14 10:44:12'),('b52bb707-5c33-4496-8de2-85a4cae483c6','7acb3d06-16d8-4718-b4ff-9164a0e3a72c',8800.00,'FCFA','accepted','paid','MTN Mobile Money','awae',NULL,'2026-09-16 00:26:28','2026-09-16 00:29:20'),('c51030ba-6b25-4a6a-acf9-056ac5ea4c23','7acb3d06-16d8-4718-b4ff-9164a0e3a72c',13800.00,'FCFA','accepted','paid','Orange Money','awae',NULL,'2026-09-16 00:27:22','2026-09-16 00:29:29');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `farmId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `price` decimal(10,2) NOT NULL,
  `stockQuantity` int DEFAULT '0',
  `unit` varchar(255) DEFAULT 'unit',
  `category` varchar(255) DEFAULT 'Live Poultry',
  `imageUrl` varchar(255) DEFAULT NULL,
  `isAvailable` tinyint(1) DEFAULT '1',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `farmId` (`farmId`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_10` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_11` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_12` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_13` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_14` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_15` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_16` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_17` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_18` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_19` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_2` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_20` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_21` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_22` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_23` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_24` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_25` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_26` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_27` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_28` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_29` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_3` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_30` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_4` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_5` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_6` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_7` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_8` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `products_ibfk_9` FOREIGN KEY (`farmId`) REFERENCES `farms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES ('0f448545-4483-454c-ab85-d6d1d67b5822','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Fresh Chicken Breast & Cuts',NULL,3800.00,179,'kg','Meat','/uploads/products/product_meat.jpg',1,'2026-09-16 00:11:20','2026-09-16 00:26:28'),('19372223-3e87-465c-b40a-e45712dcb439','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Live Broiler Chicken',NULL,4500.00,300,'bird','Live Poultry','/uploads/products/product_broiler.jpg',1,'2026-09-16 00:11:20','2026-09-16 00:11:20'),('21f51354-df8b-4cb2-8b98-7ddcf1766416','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Day-old Chicks (Pack of 50)',NULL,35000.00,200,'pack','Live Poultry','/uploads/products/product_chicks.jpg',1,'2026-09-16 00:11:20','2026-09-16 00:11:20'),('23b7cff7-09e8-43a4-b600-2f26ecd04650','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Broiler chiken','well-raised chicken, ideal for family meals or professional use.',5000.00,99,'unit','Eggs',NULL,1,'2026-09-12 17:24:59','2026-09-16 00:26:28'),('2b7218ed-aee1-4c42-9442-72be7274b624','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Layer Hen (Point of Lay)',NULL,6000.00,249,'bird','Live Poultry','/uploads/products/product_layer.jpg',1,'2026-09-16 00:11:20','2026-09-16 00:27:22'),('403b58ac-95d3-4087-87a2-9e0a5644302c','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Mature Rooster (Cockerel)',NULL,9000.00,150,'bird','Live Poultry','/uploads/products/product_rooster.jpg',1,'2026-09-16 00:11:20','2026-09-16 00:11:20'),('70b2e83a-a6d1-4dd3-8f20-f2f05ac3c782','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Layer Chicken','raised forcontinuous egg production',6000.00,50,'unit','Eggs',NULL,1,'2026-09-12 17:27:44','2026-09-12 17:27:44'),('75971f27-a90f-4870-8bbb-97328ab77b0f','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Farm-Fresh Whole Chicken',NULL,4800.00,199,'chicken','Meat','/uploads/products/product_fresh_chicken.jpg',1,'2026-09-16 00:11:20','2026-09-16 00:27:22'),('88dbd9ae-f55d-42d9-ad61-a0e041ac7b69','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Chicken eggs','fresh, carefully collected eggs from egg production.',2500.00,46,'unit','Eggs',NULL,1,'2026-09-12 17:30:27','2026-09-14 10:43:47'),('ae309483-944b-49d7-a7a9-0bfe37bcdc5a','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Farm-Fresh Table Eggs (Pack of 12)',NULL,1500.00,398,'pack','Eggs','/uploads/products/product_eggs.jpg',1,'2026-09-16 00:11:20','2026-09-16 00:27:22'),('b6c4e7b4-7fcb-4ff0-8c34-7c9b5359e871','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Poultry Starter Mash & Feed (25kg)',NULL,14500.00,100,'bag','Feed','/uploads/products/product_feed.jpg',1,'2026-09-16 00:11:20','2026-09-16 00:11:20'),('b97429ea-b233-416c-aa09-03f9ac00df86','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Layer Pellets & Grain Feed (50kg)',NULL,22000.00,80,'bag','Feed','/uploads/products/product_feed.jpg',1,'2026-09-16 00:11:20','2026-09-16 00:11:20'),('d26e3458-a44b-4c04-ba41-3d004accff23','1b997f85-baeb-4a3f-8e9a-0ab75d3f33b2','Organic Brown Eggs (Tray of 30)',NULL,3500.00,500,'tray','Eggs','/uploads/products/product_brown_eggs.jpg',1,'2026-09-16 00:11:20','2026-09-18 11:21:33');
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sensorreadings`
--

DROP TABLE IF EXISTS `sensorreadings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sensorreadings` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `deviceId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `foodLevel` float DEFAULT NULL,
  `waterLevel` float DEFAULT NULL,
  `temperature` float DEFAULT NULL,
  `humidity` float DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sensor_readings_device_id` (`deviceId`),
  KEY `sensor_readings_created_at` (`createdAt`),
  CONSTRAINT `sensorreadings_ibfk_1` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_10` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_11` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_12` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_13` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_14` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_15` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_16` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_17` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_18` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_19` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_2` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_20` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_21` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_22` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_23` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_24` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_25` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_26` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_27` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_28` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_29` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_3` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_30` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_4` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_5` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_6` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_7` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_8` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sensorreadings_ibfk_9` FOREIGN KEY (`deviceId`) REFERENCES `devices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sensorreadings`
--

LOCK TABLES `sensorreadings` WRITE;
/*!40000 ALTER TABLE `sensorreadings` DISABLE KEYS */;
INSERT INTO `sensorreadings` VALUES ('99248ca6-61d9-41f2-8057-e59455d78eee','5a0ad865-b244-47f4-833f-817c691101d3',15,85,34.5,60,'2026-09-16 00:40:41','2026-09-16 00:40:41'),('ddcc3057-663b-48a6-9039-2bc279e01aa2','5a0ad865-b244-47f4-833f-817c691101d3',15,85,34.5,60,'2026-09-12 17:31:45','2026-09-12 17:31:45');
/*!40000 ALTER TABLE `sensorreadings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('Administrator','Farmer','Customer','Delivery Person') NOT NULL DEFAULT 'Customer',
  `status` enum('pending','active','rejected','suspended','blocked') NOT NULL DEFAULT 'active',
  `avatarUrl` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `address` text,
  `lastLoginAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `rejectionReason` text,
  `approvedAt` datetime DEFAULT NULL,
  `approvedBy` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `email_2` (`email`),
  UNIQUE KEY `email_3` (`email`),
  UNIQUE KEY `email_4` (`email`),
  UNIQUE KEY `email_5` (`email`),
  UNIQUE KEY `email_6` (`email`),
  UNIQUE KEY `email_7` (`email`),
  UNIQUE KEY `email_8` (`email`),
  UNIQUE KEY `email_9` (`email`),
  UNIQUE KEY `email_10` (`email`),
  UNIQUE KEY `email_11` (`email`),
  UNIQUE KEY `email_12` (`email`),
  UNIQUE KEY `email_13` (`email`),
  UNIQUE KEY `email_14` (`email`),
  UNIQUE KEY `email_15` (`email`),
  UNIQUE KEY `email_16` (`email`),
  UNIQUE KEY `email_17` (`email`),
  UNIQUE KEY `email_18` (`email`),
  UNIQUE KEY `email_19` (`email`),
  UNIQUE KEY `email_20` (`email`),
  UNIQUE KEY `email_21` (`email`),
  UNIQUE KEY `email_22` (`email`),
  UNIQUE KEY `email_23` (`email`),
  UNIQUE KEY `email_24` (`email`),
  UNIQUE KEY `email_25` (`email`),
  UNIQUE KEY `email_26` (`email`),
  UNIQUE KEY `email_27` (`email`),
  UNIQUE KEY `email_28` (`email`),
  UNIQUE KEY `email_29` (`email`),
  UNIQUE KEY `email_30` (`email`),
  UNIQUE KEY `email_31` (`email`),
  UNIQUE KEY `email_32` (`email`),
  UNIQUE KEY `email_33` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('063c0ab0-709c-47c0-ba0a-e0336905cd25','YANG IV','francescayang15@gmail.com','$2b$10$DvweNKN8nwRRo4AeIkJtoubgfLHwnbbj8XQoGwupF4gCuTUNc3hnu','Farmer','active',NULL,'692015310',NULL,NULL,'2026-09-18 10:12:30','2026-09-18 10:12:30',NULL,NULL,NULL),('320aba61-9e02-4612-a59b-d2ad05ec0293','fav','fav@gmail.com','$2b$10$yRMXIIkd2NVD3Qsz4cJat.H9yRBN1LI0NCtBwLr0no/ZnGTeRdbSK','Customer','active','','','','2026-09-18 10:59:01','2026-09-12 17:47:45','2026-09-18 10:59:01',NULL,NULL,NULL),('37a4eb05-86ca-4bd6-8754-df24b31b4763','tim','tim@gmail.com','$2b$10$StzhnFgpiMF1F3mNUwsyyuwc1CkK6ebgzV6FTyAg7CMo/XNh32NKm','Farmer','active','','','','2026-09-18 10:52:04','2026-09-09 14:56:01','2026-09-18 10:52:04',NULL,NULL,NULL),('4dff29fc-1b4f-442d-9beb-33b0ed632d80','dev','dev@gmail.com','$2b$10$e976onfTGa4X2.q/hIvQv.yeyAKEa0MpsuXWU9HvPBK.sIq6DD4Yy','Delivery Person','active','','','','2026-09-16 00:41:41','2026-09-12 18:20:28','2026-09-16 00:41:41',NULL,NULL,NULL),('7acb3d06-16d8-4718-b4ff-9164a0e3a72c','Tom','tom@gmail.com','$2b$10$FuSbyU/TRNqdRBpLuVEziu3.DX8gRzjqbeJro0cc79dqSEmrprBFa','Customer','active',NULL,NULL,NULL,'2026-09-16 00:27:59','2026-09-16 00:06:17','2026-09-16 00:27:59',NULL,NULL,NULL),('940e9b99-1f33-433a-aa1a-25b919a0a461','jay','jay@gmail.com','$2b$10$NelfZdcgAf1KSJ.KtLngGeTH54HwRgtc4z/L3wGtXSSV5i1hY36Dm','Farmer','active','','','',NULL,'2026-09-03 13:13:24','2026-09-03 13:13:24',NULL,NULL,NULL),('9fa13ecb-3ff4-413d-8ed6-3ce457ba8e2e','cerena','cere@gmail.com','$2b$10$9ZM67lbZyRECByWp8/nGQOa12.Qnir2aJyaLbJoaGWV9cjjJ6G9yW','Administrator','active',NULL,NULL,NULL,'2026-09-15 21:29:37','2026-09-15 13:26:18','2026-09-15 21:29:37',NULL,NULL,NULL),('b51dcf39-6755-4ecc-ab9a-cb6eafe12bdc','men','men@gmail.com','$2b$10$mt5nNVdzqTN6KSxk/3ziJOkW7npBHQQPUyfZC9lovMnW6K3dDm4Ja','Customer','active','','','',NULL,'2026-09-14 10:42:56','2026-09-14 10:42:56',NULL,NULL,NULL),('d5f9a833-a618-4e19-a07c-918f9b96cb38','dalia','Dalia0@gmail.com','$2b$10$gWqgiUQvsJ5PUQ3kBXQ6/OVaKYZ2JkA.WIp60NBMp2eZQhWVymkSC','Administrator','active','','','','2026-09-16 00:29:55','2026-09-12 18:30:48','2026-09-16 00:29:55',NULL,NULL,NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-18 13:34:52
