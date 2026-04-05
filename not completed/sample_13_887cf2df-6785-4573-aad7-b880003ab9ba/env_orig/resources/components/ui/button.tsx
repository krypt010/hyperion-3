import React from 'react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export const Button = React.forwardRef<HTMLButtonElement, React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: string; size?: string }>(({ className, variant, size, ...props }, ref) => {
  return <button className={cn('inline-flex items-center justify-center rounded-md text-sm font-medium', className)} ref={ref} {...props} />;
});