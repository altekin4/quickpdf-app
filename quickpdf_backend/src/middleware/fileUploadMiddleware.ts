import multer from 'multer';
import path from 'path';
import { Request } from 'express';
import { createError } from './errorHandler';
import { validateFileUpload } from './sanitizationMiddleware';
import { logger } from '@/utils/logger';

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Determine upload directory based on file type
    let uploadDir = 'uploads/';
    
    if (file.mimetype.startsWith('image/')) {
      uploadDir += 'images/';
    } else if (file.mimetype === 'application/pdf') {
      uploadDir += 'documents/';
    } else {
      uploadDir += 'misc/';
    }
    
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Generate secure filename
    const timestamp = Date.now();
    const randomString = Math.random().toString(36).substring(2, 15);
    const extension = path.extname(file.originalname).toLowerCase();
    const sanitizedName = file.originalname
      .replace(/[^a-zA-Z0-9.-]/g, '_')
      .substring(0, 50);
    
    const filename = `${timestamp}_${randomString}_${sanitizedName}${extension}`;
    cb(null, filename);
  }
});

// File filter for security
const fileFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  try {
    // Validate file using our security function
    validateFileUpload(file);
    cb(null, true);
  } catch (error) {
    logger.warn('File upload rejected:', {
      filename: file.originalname,
      mimetype: file.mimetype,
      size: file.size,
      error: error instanceof Error ? error.message : 'Unknown error'
    });
    cb(error as Error, false);
  }
};

// Configure multer with security settings
export const secureFileUpload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max file size
    files: 5, // Maximum 5 files per request
    fields: 20, // Maximum 20 form fields
    fieldNameSize: 100, // Maximum field name size
    fieldSize: 1024 * 1024, // Maximum field value size (1MB)
  },
});

// Middleware for single file upload
export const uploadSingle = (fieldName: string) => {
  return secureFileUpload.single(fieldName);
};

// Middleware for multiple file upload
export const uploadMultiple = (fieldName: string, maxCount: number = 5) => {
  return secureFileUpload.array(fieldName, maxCount);
};

// Middleware for mixed file upload (multiple fields)
export const uploadFields = (fields: { name: string; maxCount?: number }[]) => {
  return secureFileUpload.fields(fields);
};

// Post-upload validation middleware
export const postUploadValidation = (req: Request, res: any, next: any) => {
  try {
    // Additional validation after upload
    if (req.file) {
      // Validate single file
      validateFileUpload(req.file);
      
      logger.info('File uploaded successfully:', {
        filename: req.file.filename,
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
        path: req.file.path
      });
    }
    
    if (req.files) {
      // Validate multiple files
      const files = Array.isArray(req.files) ? req.files : Object.values(req.files).flat();
      
      files.forEach((file: Express.Multer.File) => {
        validateFileUpload(file);
      });
      
      logger.info('Multiple files uploaded successfully:', {
        count: files.length,
        files: files.map(f => ({
          filename: f.filename,
          originalname: f.originalname,
          mimetype: f.mimetype,
          size: f.size
        }))
      });
    }
    
    next();
  } catch (error) {
    logger.error('Post-upload validation failed:', error);
    next(createError('File validation failed', 400));
  }
};

export default {
  secureFileUpload,
  uploadSingle,
  uploadMultiple,
  uploadFields,
  postUploadValidation,
};